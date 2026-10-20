{ lib, self }:

let
  inherit (lib) mapAttrs genAttrs;
  inherit (self) identity;

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
  */
  lazyMerge =
    lhs: rhs:
    if isAttrs lhs && isAttrs rhs then
      let
        allKeys = genAttrs (attrNames lhs ++ attrNames rhs) identity;
      in
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
