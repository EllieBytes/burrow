{
  description = "A minimal flake using Burrow";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    burrow.url = "github:EllieBytes/burrow";
    burrow.inputs.nixpkgs.follows = "nixpkgs";
    burrow.inputs.flake-parts.follows = "flake-parts";
  };

  outputs =
    inputs@{ flake-parts, burrow, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ burrow.flakeModule ];
      burrow.root = ./.;
    };
}
