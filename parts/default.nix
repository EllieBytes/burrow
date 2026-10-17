{ burrowLib }:

top@{
  config,
  ...
}:

{
  imports = [
    ./options.nix
    ./build.nix
    ./present.nix
  ];

  _module.args.burrow = rec {
    lib = burrowLib;
    build =
      {
        outputs ? config.flake,
        inputs ? top.inputs,
        burrow ? config.burrow,
      }:
      lib.build.callBuilders inputs outputs burrow;
  };
}
