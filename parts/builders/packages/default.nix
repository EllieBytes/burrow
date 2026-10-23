{
  config,
  lib,
  burrow,
  ...
}:

let
  flakeCfg = config;
  inherit (builtins) pathExists readFileType;
in
{
  burrow.builders.packages = { config, ... }: {
    discoveryFunction = burrow.lib.discoverHybrid;

    modules = [ ./modules ];

    extraSpecialArgs = {
      inherit (flakeCfg.burrow.nixpkgs) nixpkgs;
      flakeSystems = flakeCfg.systems;
    };

    searchPaths = lib.mkIf config.settings.useDefaultSearchPaths {
      pkgs = "pkgs";
      packages = "packages";
    };

    settingsModules = [
      ({ lib, ... }: {
        options = {
          useDefaultSearchPaths = lib.mkOption {
            type = lib.types.bool;
            default = true;
            example = false;
            description = ''
              Whether or not to use the default search paths.
            '';
          };
        };
      })
    ];

    buildFunctions.package =
      {
        path,
        meta,
        ...
      }:
      let
        mkPkgs =
          system:
          import (meta.nixpkgs.nixpkgs) {
            inherit (meta.nixpkgs) config overlays;
            inherit system;
          };
      in
      {
        packages = lib.genAttrs meta.systems (
          system:
          let
            pkgs = mkPkgs system;
          in
          {
            "${meta.name}" =
              if (meta.derivation == null) then
                if (readFileType path) == "directory" && pathExists (path + "/package.nix") then
                  pkgs.callPackage (path + "/package.nix") { }
                else if (readFileType path) == "regular" then
                  pkgs.callPackage path { }
                else
                  throw ''
                    burrow/packages:
                      Failed to call package `${meta.name}` directory does not contain `package.nix`
                      Please add a valid `package.nix` to the directory `${path}` or specify `meta.derivation` in meta.nix.
                  ''
              else
                meta.derivation pkgs;
          }
        );
      };
  };
}
