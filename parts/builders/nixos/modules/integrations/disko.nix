{
  config,
  lib,
  inputs,
  ...
}:

let
  inherit (lib) mkEnableOption mkOption types;
  inherit (types) listOf;
in
{
  options.disko = {
    automatic = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to automatically enable disko if a disk.nix file is found.
      '';
    };

    enable = mkEnableOption "disko integration for this host";

    disko = mkOption {
      type = types.raw;
      default =
        inputs.disko or (throw ''
          burrow/nixos:
            Host `${config.name}` enables disko integration, but no input for disko was found.
            Please add `disko` to your inputs or specify an input at `disko.disko`
        '');
    };

    diskoModule = mkOption {
      type = types.deferredModule;
      default = config.disko.disko.nixosModules.default;
      description = ''
        The module injected to add disko to your nixos configuration.
      '';
    };

    extraModules = mkOption {
      type = listOf types.deferredModule;
      default = [ ];
    };
  };
}
