{ lib, inputs, ... }:

let
  inherit (lib) mkOption mkEnableOption types;
  inherit (types)
    nullOr
    listOf
    attrsOf
    lazyAttrsOf
    ;
in
{
  options.home-manager = {
    enable = mkEnableOption "home-manager on this host";

    home-manager = mkOption {
      type = nullOr types.raw;
      default = inputs.home-manager or null;
      example = lib.literalExpression "inputs.home-manager";
      description = ''
        Home-manager input to use.
      '';
    };

    useGlobalPkgs = mkOption {
      type = types.bool;
      default = true;
      example = false;
      description = ''
        Whether or not to use tho global instance of nixpkgs (pkgs) for home-manager.
      '';
    };

    useUserPackages = mkOption {
      type = types.bool;
      default = true;
      example = false;
      description = ''
        Whether or not to use user packages.
      '';
    };

    extraSpecialArgs = mkOption {
      type = lazyAttrsOf types.unspecified;
      default = { };
      description = ''
        Extra arguments to pass to the home-manager configuration.
      '';
    };

    modules = mkOption {
      type = listOf types.deferredModules;
      default = [ ];
      description = ''
        Modules to pass to the configuration.

        NOTE:
          homeModules.default will be passed from the flake if present
      '';
    };

    users = mkOption {
      type = attrsOf types.deferredModule;
      default = { };
      description = ''
        An attribute set mapping names to home-manager modules.
        To import users from the flake structure use importUsers instead.
      '';
    };

    importUsers = mkOption {
      type = listOf types.str;
      default = [ ];
      description = ''
        An list of users to import from the flake structure.

        for each name, the configuration at homeConfigurations.<name> will be imported.
      '';
    };
  };
}
