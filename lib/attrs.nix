{ lib, ... }:

let
  inherit (lib) mapAttrs genAttrs;

  inherit (builtins)
    attrNames
    hasAttr
    head
    isAttrs
    tail
    ;

in
rec {
  /**
    # `lazySetAttrByPath`

    ```
      lazySetAttrByPath :: [ String ] -> Any -> Attrs
    ```

    Lazily sets an attribute in an attribute set by its path.
  */
  lazySetAttrByPath =
    path: value: if path == [ ] then value else { ${head path} = lazySetAttrByPath (tail path) value; };

  /**
    # `lazyMerge`

    ```
      lazyMerge :: Attrs -> Attrs -> Attrs
    ```

    Lazily merges two attribute sets recursively.
    NOTE: this function stops at attrsets with `_type` and at derivations.
  */
  lazyMerge =
    lhs: rhs:
    if isAttrs lhs && isAttrs rhs then
      let
        allKeys = genAttrs (attrNames lhs ++ attrNames rhs) (x: x);
      in
      if lhs ? _type || rhs ? _type then
        rhs
      else if (lib.isDerivation lhs) || (lib.isDerivation rhs) then
        rhs
      else
        mapAttrs (
          k: _:
          if hasAttr k lhs && hasAttr k rhs then
            lazyMerge lhs."${k}" rhs."${k}"
          else if hasAttr k lhs then
            lhs."${k}"
          else
            rhs."${k}"
        ) allKeys
    else
      rhs;
}
