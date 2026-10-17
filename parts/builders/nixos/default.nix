{
  config,
  inputs,
  lib,
  burrow,
  ...
}:

let
  inherit (lib) mkOption types;
in
{
  config.burrow.builders.nixos = {
    modules = [ ./modules ];

    searchPaths = lib.mkIf config.burrow.builders.nixos.settings.useDefaultSearchPaths {
      nixosConfigurations = "nixosConfigurations";
      hosts = "hosts";
      systems = "systems";
    };

    settingsModules = [
      {
        options.useDefaultSearchPaths = mkOption {
          type = types.bool;
          default = true;
          example = false;
          description = ''
            Whether to use default search paths if they are present.
            Cuts down on boilerplate.
          '';
        };
      }
    ];
  };
}
