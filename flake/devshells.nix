{
  perSystem = { pkgs, ... }: {
    devshells.default = {
      packages = with pkgs; [
        # General
        just

        # Nix
        nix
        nixd
        nixfmt
        package-version-server
        statix

        # Rust
        gcc
        rustc
        cargo
        clippy
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
