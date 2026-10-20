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

        builtOutputs = concatMap (
          builder:
          let
            discovered = concatMap (
              dir:
              attrValues (
                builder.discoveryFunction {
                  inherit dir inputs outputs;
                  inherit (builder) modules extraSpecialArgs;
                }
              )
            ) (attrValues (normalizeSearchPaths burrow.root builder.searchPaths));
          in
          concatMap (targetCtx: mapAttrsToList (_: f: f targetCtx) builder.buildFunctions) discovered
        ) builders;

        aggregateOutputs = concatMap (
          builder: mapAttrsToList (_: f: f builtOutputs) builder.aggregateFunctions
        ) builders;
      in
      foldl' lazyMerge { } (builtOutputs ++ aggregateOutputs);
  };
}
