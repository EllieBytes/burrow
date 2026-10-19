{
  perSystem = { pkgs, ... }: {
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
      ];
    };

    devshells.nix = {
      packages = with pkgs; [
        nix
        nixd
        nixfmt
        package-version-server
        statix
      ];
    };
  };
}
