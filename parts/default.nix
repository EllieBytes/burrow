{ burrowLib }:

top@{
  config,
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
}
