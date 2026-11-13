{ lib, ... }:

let
  inherit (builtins)
    length
    attrNames
    elem
    foldl'
    mapAttrs
    isAttrs
    isFunction
    isList
    ;
in
rec {
  /**
    # `serializable`

    ```
      serializable :: Any -> Any
    ```

    Makes any value acceptable by `nix eval --json`
  */
  serializable =
    value:
    if isAttrs value then
      (mapAttrs (_: serializable) value)
    else if isList value then
      (map serializable value)
    else if isNull value then
      ""
    else if isFunction value then
      "<function>"
    else
      value;

  /**
    # `matchEnum`

    ```
      matchEnum :: String -> Attrs -> Any
    ```

    Works much like a match statement in other languages, but uses conditional selection from attrsets.
  */
  matchEnum = val: cases: cases."${val}" or (cases.default or (throw "No Case for `${val}`"));

  extend =
    prev: exten:
    let
      ext = if exten ? extension then exten.extension else exten;
      origBuilders = attrNames prev.builders;
      builderConflicts = foldl' (conf: b: elem b origBuilders) [ ] (attrNames ext.builders);
      mergedBuilders = prev.builders // ext.builders;

      withWarnings =
        val:
        let
          warnBuilderConflicts =
            if (length builderConflicts) > 0 then
              lib.warn ''
                burrow/extend:
                  Builder conflicts, builders [ ${toString lib} ] conflict with original.
                  The extension's builders win by default.
              ''
            else
              (x: x);
        in
        warnBuilderConflicts val;
    in
    withWarnings (prev // { builders = mergedBuilders; });
}
