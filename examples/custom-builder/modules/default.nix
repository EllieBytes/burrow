{
  config,
  name,
  lib,
  inputs,
  ...
}:

{
  options = {
    # NOTE: it is good practice to declare a 'name' option for every builder.
    #       This is so that objects being built can have a different name than their directory if desired.
    name = lib.mkOption {
      type = lib.types.str;
      default = name;
    };

    system = lib.mkOption {
      type = lib.types.str;
      default = "x86_64-linux";
    };

    pkgs = lib.mkOption {
      type = lib.types.raw;
      default = import inputs.nixpkgs { inherit (config) system; };
    };
  };
}
