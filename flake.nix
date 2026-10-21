{
  description = "An easy to use and extend nix flake auto-discovery framework.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "nixpkgs";
    nix-unit.url = "github:nix-community/nix-unit";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      {
        lib,
        flake-parts-lib,
        config,
        ...
      }:
      {
        imports = [
          inputs.devshell.flakeModule
          inputs.treefmt-nix.flakeModule
          ./flake
        ];

        systems = [
          "x86_64-linux"
          "aarch64-linux"
          "aarch64-darwin"
        ];

        flake = {
          lib = import ./lib {
            inherit lib;
            extend = false;
          };

          flakeModule = (flake-parts-lib.importApply ./parts/default.nix { burrowLib = config.flake.lib; });

          flakeModules = {
            default = config.flake.flakeModule;
            burrow = config.flake.flakeModule;
          };
        };
      }
    );
}
