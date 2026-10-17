{
  config,
  lib,
  burrow,
  ...
}:

let
  inherit (lib) mkOption types;
  inherit (types) attrsOf submodule listOf;
in
{
  options.burrow = {
    root = mkOption {
      type = types.path;
      default = ../assets/blank;
      defaultText = "An empty directory";
      description = ''

      '';
    };

    builders = mkOption {
      type = attrsOf burrow.lib.types.builder;
      default = { };
      description = ''
        Builders for this flake.
      '';
    };
  };

  options.flake.burrow = {
    root = mkOption {
      type = types.path;
      default = (if config.burrow.root == null then ../assets/blank else config.burrow.root);
    };

    version = mkOption {
      type = types.str;
      default = "1.0.0-alpha";
      readOnly = true;
    };

    manifest = mkOption {
      type = submodule {
        options = {
          version = mkOption {
            type = types.str;
            default = config.flake.burrow.version;
            readOnly = true;
          };

          builders = mkOption {
            type = attrsOf (submodule {
              options = {
                name = mkOption {
                  type = types.str;
                };

                authors = mkOption {
                  type = listOf types.str;
                };

                description = mkOption {
                  type = types.str;
                };

                template_path = mkOption {
                  type = types.path;
                };

                build_functions = mkOption {
                  type = listOf types.str;
                };

                aggregate_functions = mkOption {
                  type = listOf types.str;
                };

                outputs = mkOption {
                  type = attrsOf types.str;
                };

                builder_opts = mkOption {
                  type = types.attrs;
                };
              };
            });

            default = { };
          };
        };
      };

      apply = burrow.lib.serializable;

      description = ''
        Exportable CLI schema.
      '';
    };
  };
}
