{ lib, self }:

let
  inherit (builtins)
    attrValues
    concatMap
    foldl'
    isString
    pathExists
    traceVerbose
    filter
    mapAttrs
    attrNames
    all
    elem
    ;

  inherit (lib) mapAttrsToList;
  inherit (self) lazyMerge;
in
{
  build = rec {
    /**
      # normalizeSearchPaths

      ```
        normalizeSearchPaths :: Path -> { \${name} :: (Path | String) } -> { \${name} :: Path }
      ```

      Transforms a list of both absolute paths, and stringed relative paths into a list of only absolute paths.

      Relative paths are resolved against a root path (first argument)
      Nonexistent relative paths point to an empty directory.

      Absolute paths are preserved.
    */
    normalizeSearchPaths =
      root:
      mapAttrs (
        name: cur:
        if isString cur then
          if pathExists (root + "/${cur}") then
            (root + "/${cur}")
          else
            traceVerbose "path ${cur} does not exist" ../assets/blank
        else
          cur
      );

    /**
      # callBuilders

      ```
        callBuilders :: Attrs -> Attrs -> Attrs -> Attrs
      ```

      Entrypoint for the build engine.
      Calls all builders in the specified burrow.
      Produces an attrset of all builder outputs.

      inputs: flake inputs.
      outputs: location of actual flake outputs.
      burrow: the burrow schema.
    */
    callBuilders =
      inputs: outputs: burrow:
      let
        builders = (filter (builder: builder.enable) (attrValues burrow.builders));

        discoveryFn =
          b:
          let
            required = attrNames {
              inputs = true;
              outputs = true;
              modules = true;
              extraSpecialArgs = true;
              dir = true;
            };
          in
          if (all (x: elem x required) (attrNames (builtins.functionArgs b.discoveryFunction.__functor))) then
            b.discoveryFunction
          else
            throw "Invalid discovery function for ${b.name}";

        builtOutputs = concatMap (
          builder:
          let
            discovered = concatMap (
              dir:
              attrValues (
                (discoveryFn builder) {
                  inherit dir inputs outputs;
                  inherit (builder) modules extraSpecialArgs;
                }
              )
            ) (attrValues (normalizeSearchPaths burrow.root builder.searchPaths));
          in
          concatMap (targetCtx: mapAttrsToList (_: f: f targetCtx) builder.buildFunctions) discovered
        ) builders;

        aggregateInputs = foldl' self.lazyMerge { } builtOutputs;

        aggregateOutputs = concatMap (
          builder: mapAttrsToList (_: f: f aggregateInputs) builder.aggregateFunctions
        ) builders;
      in
      foldl' lazyMerge { } (builtOutputs ++ aggregateOutputs);
  };
}
