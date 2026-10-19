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
