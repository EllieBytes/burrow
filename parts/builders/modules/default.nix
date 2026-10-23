{ burrow, lib, ... }:

let
  inherit (burrow.lib) matchEnum fs;
  inherit (builtins) readFileType pathExists;
in
{
  burrow.builders.modules = { config, ... }: {
    discoveryFunction = burrow.lib.discoverHybrid;

    modules = [
      ./modules
    ];

    searchPaths = lib.mkIf config.settings.useDefaultSearchPaths {
      modules = "modules";
      nixosModules = "nixosModules";
      homeModules = "homeModules";
      darwinModules = "darwinModules";
    };

    settingsModules = [
      ({ lib, ... }: {
        options = {
          useDefaultSearchPaths = lib.mkOption {
            type = lib.types.bool;
            default = true;
            example = false;
            description = ''
              Whether or not to use the default search paths for this builder.
            '';
          };
        };
      })
    ];

    buildFunctions.modules = { meta, path, ... }: {
      "${meta.namespace}"."${meta.name}" =
        if (readFileType path) == "directory" then
          let
            mods = matchEnum meta.scope {
              "default" = (if pathExists (path + "/default.nix") then [ (path + "/default.nix") ] else [ ]);
              "all" = (fs.intoPaths (fs.allExcept [ "meta.nix" "meta.toml" ] path) path);
              "specified" = (meta.specifiedModules);
            };
          in
          {
            imports = mods ++ meta.extraModules;
          }
        else
          {
            imports = [ path ] ++ meta.extraModules;
          };
    };
  };
}
