{
  burrow,
  config,
  lib,
  inputs,
  ...
}:

let
  nixpkgs = config.burrow.nixpkgs.nixpkgs;

  inherit (builtins)
    pathExists
    filter
    foldl'
    ;

  inherit (lib)
    mkOption
    types
    optionals
    ;

  inherit (burrow.lib.fs) allPresent intoPaths;
in
{
  config.burrow.builders.nixos =
    { config, ... }:
    let
      cfg = config;
    in
    {
      modules = [ ./modules ];

      searchPaths = lib.mkIf cfg.settings.useDefaultSearchPaths {
        nixosConfigurations = "nixosConfigurations";
        hosts = "hosts";
        systems = "systems";
        nixos = "nixos";
      };

      extraSpecialArgs = {
        inherit nixpkgs;
      };

      settingsModules = [
        {
          options.useDefaultSearchPaths = mkOption {
            type = types.bool;
            default = true;
            example = false;
            description = ''
              Whether to use default search paths if they are present.
              Cuts down on boilerplate.
            '';
          };
        }
      ];

      buildFunctions.nixos =
        {
          name,
          meta,
          path,
          ...
        }:
        let
          hm = meta.home-manager;

          base = { lib, ... }: {
            networking.hostName = lib.mkDefault meta.hostName;
            nixpkgs.config = lib.mkIf (meta.nixpkgs.config != { }) meta.nixpkgs.config;
            nixpkgs.overlays = lib.mkIf (meta.nixpkgs.overlays != [ ]) meta.nixpkgs.overlays;
          };

          hmModules = optionals hm.enable [
            (
              if hm.home-manager == null then
                throw "burrow: host '${name}' uses home-manager but no 'home-manager' input was found"
              else
                hm.home-manager.nixosModules.home-manager
            )
            {
              home-manager = {
                inherit (hm) useGlobalPkgs useUserPackages extraSpecialArgs;
                sharedModules = hm.modules;
                users = hm.users;
              };
            }
          ];

          foundModules = intoPaths (allPresent meta.files path) path;

          # Integrations.
          agenixModules = optionals meta.agenix.enable [
            meta.agenix.agenixModule
            {
              environment.systemPackages = [ meta.agenix.agenix.packages."${meta.system}".agenix ];
            }
          ];

          diskoEnabled = meta.disko.enable || (meta.disko.automatic && (pathExists (path + "/disk.nix")));
          diskoModules = optionals diskoEnabled (
            [
              meta.disko.diskoModule
            ]
            ++ meta.disko.extraModules
          );

          # Build special args.
          builtSpecialArgs = foldl' (a: b: a // b) { } (
            filter (x: x != null) [
              {
                inherit (meta) modulesPath;
                inherit inputs;
                inherit (config) flake;
              }
              (
                if meta.agenix.enable && (meta.agenix.secretsPath != null) then
                  { inherit (meta.agenix) secretsPath; }
                else
                  null
              )
            ]
          );
          specialArgs = builtSpecialArgs // meta.extraSpecialArgs;
        in
        {
          nixosConfigurations."${name}" = meta.advanced.systemFn {
            inherit specialArgs;
            inherit (meta) system;

            modules = [
              base
            ]
            ++ foundModules
            ++ hmModules
            ++ agenixModules
            ++ diskoModules
            ++ meta.extraModules;
          };
        };
    };
}
