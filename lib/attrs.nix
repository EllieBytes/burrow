{ lib, self }:

let
  inherit (lib) mapAttrs;
  inherit (self) identity;

  inherit (builtins)
    attrNames
    genAttrs
    hasAttr
    head
    isAttrs
    tail
    ;

in
rec {
  lazySetAttrByPath =
    path: value: if path == [ ] then value else { ${head path} = lazySetAttrByPath (tail path) value; };

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
