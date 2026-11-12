{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  inputs.home-manager.url = "github:nix-community/home-manager";
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";
  inputs.nixt.url = "github:nix-community/nixt";
  inputs.burrow.url = ./../..;

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.burrow.flakeModule
        ./tests
      ];

      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      burrow.root = ./.;
    };
}
