{
  inputs,
  config,
  lib,
  ...
}:

let
  inherit (lib) mkEnableOption mkOption types;
  inherit (types) nullOr;
in
{
  options.agenix = {
    enable = mkEnableOption "agenix integration for this host";

    agenix = mkOption {
      type = types.raw;
      default =
        inputs.agenix or (throw ''
          burrow/nixos:
            Host `${config.name}` enables agenix integration, but no agenix input was specified.
            Please add `agenix` to your inputs or specify at `agenix.agenix`
        '');
    };

    agenixModule = mkOption {
      type = types.deferredModule;
      default = inputs.agenix.darwinModules.default;
      description = ''
        module to inject adding agenix integration to the host.
      '';
    };

    secretsPath = mkOption {
      type = nullOr types.path;
      default = null;
      description = ''
        Path to global secrets directory.
        If specified, will be injected as `secretsPath` in specialArgs.
      '';
    };
  };
}
