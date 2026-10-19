{
  config,
  lib,
  ...
}:

let
  inherit (builtins)
    pathExists
    listToAttrs
    match
    ;

  inherit (lib) mkOption types optionals;

  re = "^([a-zA-Z0-9._%+-]+)@([a-zA-Z0-9\\..-]+)";
  isBound = name: (match re name) != null;
  bestUser =
    hostname: want:
    if (isBound want) then
      config.flake.homeConfigurations."${want}" or throw "${want} does not exist."
    else if config.flake.homeConfigurations ? "${want}@${hostname}" then
      config.flake.homeConfigurations."${want}@${hostname}"
    else
      config.flake.homeConfigurations."${want}" or throw "${want} does not exist.";
in
{
  config.burrow.builders.nixos = {
    modules = [ ./modules ];

    searchPaths = lib.mkIf config.burrow.builders.nixos.settings.useDefaultSearchPaths {
      nixosConfigurations = "nixosConfigurations";
      hosts = "hosts";
      systems = "systems";
      nixos = "nixos";
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
      {
        nixosConfigurations."${name}" = meta.advanced.systemFn {
          inherit (meta) system extraModules;

          modules = [
            (if pathExists (path + "/configuration.nix") then (path + "/configuration.nix") else { })
          ]
          ++ (optionals meta.home-manager.enable [
            meta.home-manager.home-manager.nixosModules.home-manager
            ({ config, ... }: {
              home-manager = {
                inherit (meta.home-manager) enable useGlobalPkgs useUserPackages;
                users =
                  let
                    imported = (
                      listToAttrs (
                        map (user: {
                          name = user;
                          value = bestUser config.networking.hostName user;
                        }) meta.home-manager.importUsers
                      )
                    );
                  in
                  imported // meta.home-manager.users;
              };
            })
          ]);

          specialArgs = { } // meta.extraSpecialArgs;
        };
      };
  };
}
