{
  name,
  lib,
  inputs,
  config,
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
        inputs.home-manager
          or (throw "Could not find input home-manager. please add home-manager to your inputs, or specify an input to use");
    };

    system = mkOption {
      type = types.str;
      default = builtins.currentSystem;
      description = ''
        The system (hostPlatform) to use
      '';
    };

    buildForHosts = mkOption {
      type = listOf types.str;
      default = [ ];
      description = ''

      '';
    };

    username = mkOption {
      type = types.str;
      default = "";
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
      default =
        if inputs ? nixpkgs then
          import inputs.nixpkgs { }
        else
          throw "Could not find nixpkgs inputs to instance. Please add nixpkgs to your inputs or specify 'pkgs' manually.";
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
