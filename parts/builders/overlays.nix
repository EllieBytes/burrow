{
  burrow,
  config,
  lib,
  inputs,
  ...
}:

let
  inherit (builtins)
    attrValues
    any
    elem
    attrNames
    ;

  flakeCfg = config;
in
{
  burrow.builders.overlays = { config, ... }: {
    # NOTE: Might want to change this, but I dont think there is any place for a meta.nix at all.
    discoveryFunction = burrow.lib.flatDiscoverByFile;

    searchPaths = lib.mkIf config.settings.useDefaultSearchPaths {
      overlays = "overlays";
    };

    settingsModules = [
      ({ lib, ... }: {
        options = {
          useDefaultSearchPaths = lib.mkOption {
            type = lib.types.bool;
            default = true;
            example = false;
            description = ''
              Whether to use the default search paths for this builder.
            '';
          };

          combineOverlays = lib.mkOption {
            type = lib.types.bool;
            default = false;
            example = true;
            description = ''
              Whether to combine all overlays into a single overlay.
            '';
          };

          combinedOverlayName = lib.mkOption {
            type = lib.types.str;
            default = "default";
            example = "combined";
            description = ''
              Name of the combined overlay.
            '';
          };
        };
      })
    ];

    buildFunctions.overlay =
      { name, path, ... }:
      let
        deferOverlay =
          o: args:
          let
            req = [
              "inputs"
              "outputs"
            ];
            args = builtins.functionArgs o;
          in
          if (any (x: elem x req) (attrNames args)) then o args else o;

      in
      {
        overlays."${name}" =
          if (builtins.pathExists path) then
            deferOverlay (import path) {
              inherit inputs;
              outputs = config.flake;
            }
          else
            (_: _: { });
      };

    aggregateFunctions.combined =
      { outputs, ... }:
      if (config.settings.combineOverlays) then
        {
          overlays."${config.settings.combinedOverlayName}" = (
            flakeCfg.burrow.nixpkgs.nixpkgs.lib.composeManyExtensions (attrValues outputs.overlays)
          );
        }
      else
        { };
  };
}
