{
  name,
  lib,
  inputs,
  config,
  pkgsFor,
  ...
}:

let
  inherit (lib) mkOption types;
  inherit (types) listOf lazyAttrsOf functionTo;
in
{
  options = {
    name = mkOption {
      type = types.str;
      default = name;
      description = ''
        The name of this configuration.
      '';
    };

    home-manager = mkOption {
      type = types.raw;
      default =
        inputs.home-manager or (throw ''
          burrow/home-manager:
            Could not find input home-manager.
            Please add `home-manager` to your inputs, or specify at `home-manager`.
        '');
    };

    files = mkOption {
      type = listOf types.str;
      default = [
        "home.nix"
        "default.nix"
      ];
      description = ''
        Files to auto-import if found.
      '';
    };

    system = mkOption {
      type = types.str;
      default = builtins.currentSystem;
      description = ''
        The system (hostPlatform) to use
      '';
    };

    username = mkOption {
      type = types.str;
      default = config.name;
      description = ''
        The name of this user.
      '';
    };

    homeDirectory = mkOption {
      type = types.str;
      default = "/home/${config.username}";
      description = ''
        The home directory of this user.
      '';
    };

    extraModules = mkOption {
      type = listOf types.deferredModule;
      default = [ ];
      description = ''
        Extra modules to apply to this configuration.
      '';
    };

    extraSpecialArgs = mkOption {
      type = lazyAttrsOf types.unspecified;
      default = { };
      description = ''
        Extra arguments to pass to modules under this configuration.
      '';
    };

    lib = mkOption {
      type = types.unspecified;
      default = config.pkgs.lib;
      description = ''
        The 'lib' to pass to this instance.
      '';
    };

    minimal = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = ''
        Whether or not this should be a minimal config.
      '';
    };

    pkgs = mkOption {
      type = types.raw;
      default = pkgsFor."${config.system}";
    };

    advanced = {
      homeFn = mkOption {
        type = functionTo types.unspecified;
        default = config.home-manager.lib.homeManagerConfiguration;
        description = ''
          The function used to build the home-manager configuration.
        '';
      };
    };
  };
}
