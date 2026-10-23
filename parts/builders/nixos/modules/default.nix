{
  name,
  config,
  lib,
  nixpkgs,
  ...
}:

let
  inherit (lib) mkOption types;
  inherit (types)
    listOf
    functionTo
    lazyAttrsOf
    nullOr
    ;

  markAdvanced =
    desc:
    desc
    + "\n"
    + ''
      > [!WARNING]
      > This is an advanced option
      > This means you likely should not be changing it unless you know what you are doing.
    '';

  mkAdvancedOption =
    args@{
      description ? "",
      ...
    }:
    mkOption (args // { description = markAdvanced description; });
in
{
  imports = [
    ./integrations
  ];

  options = {
    name = mkOption {
      type = types.str;
      default = name;
      description = ''
        Name of this host.
      '';
    };

    hostName = mkOption {
      type = types.str;
      default = config.name;
      description = ''
        Hostname of this host.
        Mapped to `networking.hostName`
      '';
    };

    system = mkOption {
      type = types.str;
      default = builtins.currentSystem;
      example = "aarch64-linux";
      description = ''
        The system (host platform) for this system.
      '';
    };

    files = mkOption {
      type = listOf types.str;
      default = [
        "default.nix"
        "configuration.nix"
        "hardware-configuration.nix"
      ];
      description = ''
        Files in the host directory to import automatically.
      '';
    };

    extraSpecialArgs = mkOption {
      type = lazyAttrsOf types.unspecified;
      default = { };
      description = ''
        Extra arguments to pass to modules under this host.
      '';
    };

    extraModules = mkOption {
      type = listOf types.deferredModule;
      default = [ ];
      description = ''
        Modules to pass to the host config.
      '';
    };

    modulesPath = mkOption {
      type = nullOr types.path;
      default = null;
      description = ''
        NixOS module path to inject as `modulesPath`.
      '';
    };

    lib = mkOption {
      type = types.raw;
      default = lib;
      description = ''
        The lib to be passed to the system.
      '';
    };

    nixpkgs = {
      nixpkgs = mkOption {
        type = types.raw;
        default = nixpkgs;
        example = lib.literalExpression "inputs.nixpkgs";
        description = ''
          The nixpkgs input to use.
        '';
      };

      config = mkOption {
        type = lib.types.attrs;
        default = { };
        description = ''
          Settings for nixpkgs.
        '';
      };

      overlays = mkOption {
        type = listOf (functionTo types.raw);
        default = [ ];
        example = lib.literalExpression ''
          [ (final: prev: { /* Your changes here... */ }) ]
        '';
        description = ''
          Overlays to be applied to nixpkgs.
        '';
      };
    };

    advanced.systemFn = mkAdvancedOption {
      type = functionTo types.raw;
      default = config.nixpkgs.nixpkgs.lib.nixosSystem;
      description = ''
        The function used to produce the final system.
      '';
    };
  };
}
