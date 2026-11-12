{ lib, self }:

let
  inherit (builtins)
    attrValues
    hasAttr
    isAttrs
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

  inherit (lib) mapAttrsToList filterAttrs genAttrs;
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

    discoveryFn =
      b:
      let
        args = lib.functionArgs b.discoveryFunction;
        allowed = [
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
    /**
      # callBuilders

      ```
        callBuilders :: Attrs -> Attrs -> Attrs -> Attrs
      ```

      Entrypoint for the build engine.
      Calls all builders in the specified burrow.
      Produces an attrset of all builder outputs.

      outputs: location of actual outputs.
      burrow: the burrow schema.
      args: extra arguments.
    */
    callBuilders =
      outputs: burrow: args:
      let
        builders = (filterAttrs (_: builder: builder.enable) burrow.builders);
        discovered = callDiscoveries outputs burrow args;
        flattenContexts = perPath: concatMap attrValues (attrValues perPath);

        builtOutputs = concatLists (
          mapAttrsToList (
            key: builder:
            concatMap (ctx: mapAttrsToList (_: f: f ctx) builder.buildFunctions) (
              flattenContexts discovered."${key}"
            )
          ) builders
        );

        aggregateInputs = assemble builtOutputs;
        aggregateContext = {
          outputs = aggregateInputs;
          inherit discovered;
        };

        aggregateOutputs = concatMap (
          builder: mapAttrsToList (_: f: f aggregateContext) builder.aggregateFunctions
        ) (attrValues builders);
      in
      assemble (builtOutputs ++ aggregateOutputs);

    /**
      # `callDiscoveries`

      ```
        callDiscoveries :: Attrs -> Attrs -> Attrs -> Attrs
      ```

      Calls just the discovery step of every enabled builder.

      Produces a structure where

      <builder_name>.<builder_search_path>.<discovered_name> = <target_context>
    */
    callDiscoveries =
      outputs: burrow: args:
      mapAttrs (
        key: builder:
        mapAttrs (
          _: dir:
          (discoveryFn builder) {
            inherit dir outputs;
            inherit (builder) modules;
            extraSpecialArgs = args // builder.extraSpecialArgs;
          }
        ) (normalizeSearchPaths burrow.root builder.searchPaths)
      ) (filterAttrs (_: builder: builder.enable) burrow.builders);

    /**
      # `assemble`

      ```
        assemble :: [Attrs] -> Attrs
      ```

      Assembles and merges a list of outputs.

      Currently counts leaves as any non attrset, derivation, or attrset containing the following key.

      - _type
      - __functor
      - outpath
    */
    assemble =
      outputs:
      let
        mergeOutputs =
          lhs: rhs:
          if isAttrs lhs && isAttrs rhs then
            let
              allKeys = genAttrs (attrNames lhs ++ attrNames rhs) (x: x);
            in
            if lhs ? _type || rhs ? _type then
              rhs
            else if (lib.isDerivation lhs) || (lib.isDerivation rhs) then
              rhs
            else if lhs ? __functor || rhs ? __functor then
              rhs
            else if lhs ? outPath || rhs ? outPath then
              rhs
            else
              mapAttrs (
                k: _:
                if hasAttr k lhs && hasAttr k rhs then
                  mergeOutputs lhs."${k}" rhs."${k}"
                else if hasAttr k lhs then
                  lhs."${k}"
                else
                  rhs."${k}"
              ) allKeys
          else
            rhs;
      in
      foldl' mergeOutputs { } outputs;
  };
}
