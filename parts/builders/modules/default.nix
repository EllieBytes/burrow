{ burrow, lib, ... }:

let
  inherit (burrow.lib) matchEnum fs;
  inherit (builtins)
    readFileType
    pathExists
    filter
    isString
    ;
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
      flakeModules = "flakeModules";
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

          namespaces = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            default = { };
            example = {
              nixosModules = "nixosModules";
              myModules = "nixosModules";
            };

            description = ''
              A mapping of searchPath keys to their namespaces.
            '';
          };
        };
      })
    ];

    buildFunctions.modules =
      {
        meta,
        path,
        top,
        ...
      }:
      let
        resolvedNamespace =
          if meta.namespace == null || meta.namespace == "" then fs.baseNameOf top else meta.namespace;
      in
      {
        "${resolvedNamespace}"."${meta.name}" =
          if (readFileType path) == "directory" then
            let
              mods = matchEnum meta.scope {
                "default" = (if pathExists (path + "/default.nix") then [ (path + "/default.nix") ] else [ ]);
                "all" = (fs.intoPaths filter ((x: x != "meta.nix") (fs.nixFiles path)) path);
                "specified" = map (x: if isString x then fs.intoPaths [ x ] path else x) (meta.specifiedModules);
              };
            in
            {
              _file = path;
              imports = mods ++ meta.extraModules;
            }
          else
            {
              _file = path;
              imports = [ path ] ++ meta.extraModules;
            };
      };
  };
}
