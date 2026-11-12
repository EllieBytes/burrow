{ lib, self, ... }:

let
  inherit (lib) mkOption types;
  inherit (types)
    attrsOf
    lazyAttrsOf
    listOf
    mkOptionType
    ;

  mkPkgs =
    nixpkgs: config: overlays: system:
    if config == { } && overlays == [ ] then
      nixpkgs.legacyPackages.${system}
    else
      import nixpkgs {
        inherit system config overlays;
      };
in
lib.types.submodule (
  { config, ... }: {
    options = {
      nixpkgs = {
        nixpkgs = mkOption {
          type = types.raw;
          default = null;
          description = ''
            Default nixpkgs input to use.
          '';
        };

        config = mkOption {
          type = types.attrs;
          default = { };
          description = ''
            Default config for nixpkgs.
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
            Default overlays for nixpkgs.
          '';
        };
      };

      pkgs = mkOption {
        type = lazyAttrsOf types.raw;
        readOnly = true;
        default = lib.genAttrs (lib.unique (config.systems ++ lib.systems.flakeExposed)) (
          mkPkgs config.nixpkgs.nixpkgs config.nixpkgs.config config.nixpkgs.overlays
        );
      };

      root = mkOption {
        type = types.path;
        default = ../../assets/blank;
        defaultText = "An empty directory";
        description = ''
          The root of your project, allows builders to automatically populate search paths.
        '';
      };

      builders = mkOption {
        type = attrsOf self.types.builder;
        default = { };
        description = ''
          Builders for this burrow.
        '';
      };

      systems = mkOption {
        type = listOf types.str;
        default = [ ];
        description = ''
          Systems for this burrow.
        '';
      };
    };
  }
)
