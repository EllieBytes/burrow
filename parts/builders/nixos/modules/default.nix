{
  config,
  lib,
  inputs,
  ...
}:

let
  inherit (lib) mkOption types;
  inherit (types) listOf functionTo lazyAttrsOf;

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
    ./home-manager.nix
  ];

  options = {
    system = mkOption {
      type = types.str;
      default = builtins.currentSystem;
      example = "aarch64-linux";
      description = ''
        The system (host platform) for this system.
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
        default =
          inputs.nixpkgs or throw
            "No nixpkgs input found. Please add 'nixpkgs' to your inputs, or specify the channel in 'nixpkgs.nixpkgs'";
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

    advanced = {
      systemFn = mkAdvancedOption {
        type = functionTo types.raw;
        default = config.nixpkgs.nixpkgs.lib.nixosSystem;
        description = ''
          The function used to produce the final system.
        '';
      };

      # NOTE: I may need to move this, I'm not quite sure where it fits atm...
      prefix = mkAdvancedOption {
        type = listOf types.str;
        default = [ ];
      };
    };
  };
}
