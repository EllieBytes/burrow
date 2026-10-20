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
    # `identity`

    ```
      identity :: Any -> Any
    ```

    Returns the first argument.
  */
  identity = x: x;

  /**
    # `deprioritize`

    ```
      deprioritize :: Int -> Path -> DeferredModule
    ```

    Lowers the priority of an entire module. Items in the module with an existing override priority are preserved.
  */
  deprioritize =
    priority: file: module:
    { lib, options, ... }@args:
    let
      inherit (builtins) isFunction isAttrs;
      inherit (lib) mkOverride attrByPath isOption;

      resolved = if isFunction module then module args else module;

      structural = [
        "imports"
        "config"
        "options"
        "_module"
        "_file"
        "_class"
        "key"
        "disabledModules"
      ];

      hasStructure = isAttrs resolved && builtins.any (k: resolved ? ${k}) structural;
      rawConfig = if hasStructure then resolved.config or { } else resolved;

      typeOf' = v: if isAttrs v then v._type or null else null;

      wrap =
        path: value:
        let
          t = typeOf' value;
        in
        if t == "override" then
          value
        else if t == "if" || t == "order" then
          value // { content = wrap path value.content; }
        else if t == "merge" then
          value // { content = map (wrap path) value.contents; }
        else if t == "definition" then
          value // { value = wrap path value.value; }
        else if isOption (attrByPath path null options) then
          mkOverride priority value
        else if isAttrs value then
          mapAttrs (k: v: wrap (path ++ [ k ]) v) value
        else
          mkOverride priority value;
    in
    (if hasStructure then removeAttrs resolved [ "config" ] else { })
    // {
      _file = file;
      config = wrap [ ] rawConfig;
    };

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
