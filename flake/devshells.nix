{ inputs, ... }:

{
  perSystem = { pkgs, system, ... }: {
    devshells.default = {
      packages = with pkgs; [
        # General
        just
        direnv

        # Nix
        nix
        nixd
        nixfmt
        package-version-server
        statix
        inputs.nixt.packages."${system}".default
      ];
    };

    devshells.nix = {
      packages = with pkgs; [
        nix
        nixd
        nixfmt
        package-version-server
        statix
        inputs.nixt.package."${system}".default
      ];
    };
  };
}
