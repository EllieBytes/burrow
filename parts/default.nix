{ burrowLib }:

top@{
  config,
  inputs,
  lib,
  ...
}:

{
  imports = [
    ./options.nix
    ./build.nix
  ];

  _module.args.burrow = rec {
    lib = burrowLib;
    build =
      {
        outputs ? config.flake,
        inputs ? top.inputs,
        burrow ? config.burrow,
      }:
      lib.build.callBuilders outputs burrow { inherit inputs; };
  };

  burrow.nixpkgs.nixpkgs = lib.mkDefault inputs.nixpkgs or throw ''
    burrow/flake-parts:
      No `nixpkgs` input found. Please add `nixpkgs` to your inputs or specify burrow.nixpkgs.nixpkgs.
  '';
}
