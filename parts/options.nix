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
      import burrow.nixpkgs.nixpkgs {
        inherit system;
        inherit (cfg.nixpkgs) config overlays;
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

    builders = mkOption {
      type = attrsOf burrow.lib.types.builder;
      default = config.burrow.builders;
      readOnly = true;
    };

    discovered = mkOption {
      type = attrsOf types.unspecified;
      default = burrow.lib.build.callDiscoveries inputs config.flake config.burrow;
      readOnly = true;
    };
  };
}
