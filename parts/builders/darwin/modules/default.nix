{
  name,
  config,
  lib,
  inputs,
  ...
}:

let
  inherit (lib) mkOption types;
  inherit (types)
    listOf
    functionTo
    lazyAttrsOf
    nullOr
    enum
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
      type = enum [
        "aarch64-darwin"
        "x86_64-darwin"
      ];

      default = "aarch64-darwin";
      example = "x86_64-darwin";
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

    nix-darwin = mkOption {
      type = types.raw;
      default =
        inputs.nix-darwin or (throw ''
          burrow/darwin:
            No input for `nix-darwin` found.
            Please add `nix-darwin` to your inputs or specify at `nix-darwin` in your `meta.nix`.
        '');
    };

    nixpkgs = {
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
      default = config.nix-darwin.lib.darwinSystem;
      description = ''
        The function used to produce the final system.
      '';
    };
  };
}
