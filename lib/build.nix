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
    ;

  inherit (lib) mapAttrsToList;
  inherit (self) lazyMerge;
in
{
  build = rec {
    normalizeSearchPaths =
      root:
      map (
        cur:
        if isString cur then
          if pathExists (root + "/${cur}") then
            (root + "/${cur}")
          else
            traceVerbose "path ${cur} does not exist" ../assets/blank
        else
          cur
      );

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
            ) (normalizeSearchPaths burrow.root (attrValues builder.searchPaths));
          in
          concatMap (targetCtx: mapAttrsToList (_: f: f targetCtx) builder.buildFunctions) discovered
        ) (attrValues burrow.builders);

        aggregateOutputs = concatMap (
          builder: mapAttrsToList (_: f: f builtOutputs) builder.aggregateFunctions
        ) (attrValues burrow.builders);
      in
      foldl' lazyMerge { } (builtOutputs ++ aggregateOutputs);
  };
}
