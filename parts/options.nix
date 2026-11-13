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
}
