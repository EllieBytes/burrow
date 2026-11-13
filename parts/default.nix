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
      burrowLib.build.callBuilders outputs burrow { inherit inputs; };
  };

  burrow.nixpkgs.nixpkgs = lib.mkDefault (
    inputs.nixpkgs or (throw ''
      burrow/flake-parts:
        No `nixpkgs` input found. Please add `nixpkgs` to your inputs or specify burrow.nixpkgs.nixpkgs.
    '')
  );

  flake.burrow = burrowLib.build.present config.flake config.burrow { inherit inputs; };

  flake.packages = lib.genAttrs (config.systems) (system: {
    burrow.doc = burrowLib.document config.flake config.burrow { inherit inputs; } system;
  });
}
