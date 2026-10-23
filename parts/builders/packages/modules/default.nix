{
  name,
  lib,
  nixpkgs,
  flakeSystems,
  ...
}:

let
  inherit (lib) mkOption types;
  inherit (types) listOf functionTo nullOr;
in
{
  options = {
    name = mkOption {
      type = types.str;
      default = name;
      description = ''
        Name of this package.
      '';
    };

    systems = mkOption {
      type = listOf types.str;
      default = flakeSystems;
      description = ''
        List of systems to build this package for.
      '';
    };

    nixpkgs = {
      nixpkgs = mkOption {
        type = types.raw;
        default = nixpkgs;
        description = ''
          Nixpkgs input to use for this package.
        '';
      };

      overlays = mkOption {
        type = listOf (functionTo types.raw);
        default = [ ];
        description = ''
          Overlays to apply to nixpkgs.
        '';
      };

      config = mkOption {
        type = types.attrs;
        default = { };
        description = ''
          Configuration for nixpkgs.
        '';
      };
    };

    derivation = mkOption {
      type = nullOr (functionTo types.raw);
      default = null;
      description = ''
        Function of (pkgs: <derivation>)

        If unspecified `package.nix` will be called with `pkgs.callPackage`

        NOTE: It is very unrecommended to declare this in a top-level meta.nix
      '';
    };
  };
}
