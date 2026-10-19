{
  burrow.builders.my-builder = {
    modules = [
      ./modules
    ];

    # This path will search relative to config.burrow.root.
    # Useful for declaring a structure, but not requiring that structure be present.
    searchPaths.default = "my-path";

    buildFunctions.my-build-func =
      {
        name, # Name of the thing being built.
        meta, # Evaluated meta.nix of the thing being built.
        path, # Path to the directory being built.
        ...
      }:
      {
        # This attrset will be merged with config.flake
        packages."${meta.system}"."${meta.name}" = meta.pkgs.hello;
      };

    # Aggregate functions are useful if all your outputs need to combine into something.
    # E.g. a colmena hive.
    aggregateFunctions.my-agg-func =
      outputs: # This contains the output of all builders including the current one.
      {
        overlays."x86_64-linux".default = (final: prev: outputs.packages."x86_64-linux");
      };
  };
}
