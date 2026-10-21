{ ... }:

let
  inherit (builtins)
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
}
