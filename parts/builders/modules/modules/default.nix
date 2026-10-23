{ name, lib, ... }:

let
  inherit (lib) mkOption types;
  inherit (types) enum listOf;
in
{
  options = {
    namespace = mkOption {
      type = types.str;
      default = "nixosModules";
      example = "homeModules";
      description = ''
        Namespace to place this module in.
        Modules will placed in `outpus.<namespace>.<name>`
      '';
    };

    name = mkOption {
      type = types.str;
      default = name;
      description = ''
        Name of this module.
      '';
    };

    scope = mkOption {
      type = enum [
        "all"
        "default"
        "specified"
      ];

      default = "default";
      description = ''
        The scope of the built module (applies only to directories, and not files).
        "all"       -> All modules in that directory.
        "default"   -> Only the default.nix for that directory.
        "specified" -> Only modules under `specifiedModules`
      '';
    };

    specifiedModules = mkOption {
      type = listOf types.deferredModule;
      default = [ ];
      description = ''
        List of modules to import if `scope == "specified"`
      '';
    };

    extraModules = mkOption {
      type = listOf types.deferredModule;
      default = [ ];
      description = ''
        Extra modules to combine into this one.
      '';
    };
  };
}
