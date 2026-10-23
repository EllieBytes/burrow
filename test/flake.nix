{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.home-manager.url = "github:nix-community/home-manager";
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";
  inputs.burrow.url = ./..;

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.burrow.flakeModule
      ];

      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      burrow.root = ./.;
      burrow.builders.overlays.settings.combineOverlays = true;
      burrow.builders.overlays.settings.combinedOverlayName = "combined";
    };
}
