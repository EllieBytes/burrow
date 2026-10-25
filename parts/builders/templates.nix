{ lib, ... }:

{
  burrow.builders.templates = { config, ... }: {
    settingsModules = [
      {
        useDefaultSearchPaths = lib.mkOption {
          type = lib.types.bool;
          default = true;
          example = false;
          description = ''
            Whether to use the default search paths for this builder.
          '';
        };
      }
    ];

    searchPaths = lib.mkIf config.settings.useDefaultSearchPaths {
      templates = "templates";
    };

    modules = [
      (
        { lib, ... }:
        let
          inherit (lib) mkOption types;
        in
        {
          options = {
            description = mkOption {
              type = types.str;
              default = "";
            };

            welcomeText = mkOption {
              type = types.str;
              default = "";
            };
          };
        }
      )
    ];

    buildFunctions.template =
      {
        name,
        path,
        meta,
        ...
      }:
      {
        templates."${name}" = {
          inherit path;
          inherit (meta) description welcomeText;
        };
      };
  };
}
