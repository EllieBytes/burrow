{ lib, self }:

let
  inherit (builtins)
    attrValues
    concatMap
    foldl'
    isString
    pathExists
    traceVerbose
    mapAttrs
    attrNames
    all
    elem
    concatLists
    ;

  inherit (lib) mapAttrsToList filterAttrs;
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
        builders = (filterAttrs (_: builder: builder.enable) burrow.builders);

        discoveryFn =
          b:
          let
            args = lib.functionArgs b.discoveryFunction;
            allowed = [
              "inputs"
              "outputs"
              "modules"
              "extraSpecialArgs"
              "dir"
            ];
          in
          if args ? dir && (all (x: elem x allowed) (attrNames args)) then
            b.discoveryFunction
          else
            throw ''
              Invalid discovery function for ${b.name}
              Expected arguments: ${toString allowed}
              Got arguments: ${toString (attrNames args)}
            '';

        discovered = mapAttrs (
          key: builder:
          mapAttrs (
            _: dir:
            (discoveryFn builder) {
              inherit dir inputs outputs;
              inherit (builder) modules extraSpecialArgs;
            }
          ) (normalizeSearchPaths burrow.root builder.searchPaths)
        ) builders;

        flattenContexts = perPath: concatMap attrValues (attrValues perPath);

        builtOutputs = concatLists (
          mapAttrsToList (
            key: builder:
            concatMap (ctx: mapAttrsToList (_: f: f ctx) builder.buildFunctions) (
              flattenContexts discovered."${key}"
            )
          ) builders
        );

        aggregateInputs = foldl' self.lazyMerge { } builtOutputs;
        aggregateContext = {
          outputs = aggregateInputs;
          inherit discovered;
        };

        aggregateOutputs = concatMap (
          builder: mapAttrsToList (_: f: f aggregateContext) builder.aggregateFunctions
        ) (attrValues builders);
      in
      foldl' lazyMerge { } (builtOutputs ++ aggregateOutputs);
  };
}
