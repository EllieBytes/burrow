{
  config,
  lib,
  burrow,
  inputs,
  ...
}:

let
  cfg = config.burrow;
  inherit (builtins) filter;
  inherit (lib) mkOption types;
  inherit (types)
    attrsOf
    submodule
    listOf
    either
    mkOptionType
    lazyAttrsOf
    ;

  mkPkgs =
    system:
    if cfg.nixpkgs.overlays == [ ] && cfg.nixpkgs.config == { } then
      cfg.nixpkgs.nixpkgs.legacyPackages."${system}"
    else
      import cfg.nixpkgs.nixpkgs {
        inherit system;
        inherit (cfg) config overlays;
      };
in
{
  options.burrow = {
    nixpkgs = {
      nixpkgs = mkOption {
        type = types.raw;
        default =
          inputs.nixpkgs or (throw ''
            burrow: no 'nixpkgs' input found.
              Please add 'nixpkgs' to your inputs or specify one manually at 'burrow.nixpkgs.nixpkgs'
          '');
        description = ''
          Default nixpkgs input.
        '';
      };

      config = mkOption {
        type = types.attrs;
        default = { };
        description = ''
          Default nixpkgs config.
        '';
      };

      overlays = mkOption {
        type = listOf (mkOptionType {
          name = "nixpkgs-overlay";
          description = "nixpkgs overlay";
          check = lib.isFunction;
          merge = lib.mergeOneOption;
        });

        default = [ ];
        description = ''
          Default nixpkgs overlays.
        '';
      };
    };

    pkgs = mkOption {
      type = lazyAttrsOf types.raw;
      readOnly = true;
      description = ''
        Default shared nixpkgs instances.
        Saves evaluation cost for builders.
      '';
      default = lib.genAttrs (lib.unique (config.systems ++ lib.systems.flakeExposed)) mkPkgs;
    };

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

                search_paths = mkOption {
                  type = listOf (either types.str types.path);
                  apply = filter (x: x == ../assets/blank);
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
