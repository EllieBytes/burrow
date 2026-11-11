{
  config,
  lib,
  burrow,
  inputs,
  ...
}:

let
  inherit (lib) mkOption types;
  inherit (types) attrsOf;
in
{
  options.burrow = mkOption {
    type = burrow.lib.types.burrow;
    default = {
      nixpkgs.nixpkgs = inputs.nixpkgs or throw ''
        burrow:
          No input for `nixpkgs`. please add nixpkgs to your input or specify an input to use.
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
      default = "26.11";
      readOnly = true;
    };

    builders = mkOption {
      type = attrsOf burrow.lib.types.builder;
      default = config.burrow.builders;
      readOnly = true;
    };

    discovered = mkOption {
      type = attrsOf types.unspecified;
      default = burrow.lib.build.callDiscoveries config.flake config.burrow { inherit inputs; };
      readOnly = true;
    };
  };
}
