{ lib, self, ... }:

let
  inherit (lib) filterAttrs;
  inherit (self.fs) isHidden subdirNames;

  inherit (builtins)
    filter
    listToAttrs
    pathExists
    match
    readDir
    elemAt
    attrNames
    readFile
    ;

in
rec {
  /**
    # `dirIgnored`

    ```
      dirIgnored :: Path -> Bool;
    ```

    Determines whether a directory contains a `.burrow_skip` file and should be ignored.
    Use of this file is conventional throughout discovery functions.
  */
  dirIgnored = dir: pathExists (dir + "/.burrow_skip");

  /**
    # `evalMeta`

    ```
      evalMeta :: {
        name :: String,
        inputs :: Attrs,
        outputs :: Attrs,
        modules :: [ DeferredModule ],
        extraSpecialArgs :: Attrs
      } -> Module
    ```

    Thin wrapper over lib.evalModules for meta.nix files.
  */
  evalMeta =
    {
      name ? "",
      inputs ? { },
      outputs ? { },
      modules ? [ ],
      extraSpecialArgs ? { },
    }:
    lib.evalModules {
      inherit modules;

      specialArgs = lib.recursiveUpdate {
        inherit
          lib
          name
          inputs
          outputs
          ;

      } extraSpecialArgs;
    };

  /**
    # `deferMeta`

    ```
      deferMeta :: (NullOr Path) -> (NullOr DeferredModule)
    ```

    Accepts a path to a Nix or TOML file.
    Loads whichever it finds, null if none.

    (NOTE: it is the caller's job to handle the case where there is both a meta.nix and meta.toml/meta.tml)
  */
  deferMeta =
    file:
    let
      ext =
        let
          m = builtins.match ".*\\.([^.]+)$" (toString file);
        in
        if m == null then "" else elemAt m 0;
    in
    if pathExists file then
      if isNull file then
        null
      else if ext == "nix" then
        (import file)
      else if ext == "toml" || ext then
        (fromTOML (readFile file))
      else
        null
    else
      null;

  /**
    # `flatDisccoverByFile`

    ```
      flatDiscoverByFile :: DiscoveryArgs -> { \${name} :: { name :: String, path :: String, top :: String } }
    ```

    Discovers files, does not take or evaluate a meta.nix at all.
  */
  flatDiscoverByFile =
    { dir, ... }:
    let
      nixFiles = attrNames (
        filterAttrs (
          name: kind:
          ((match "^(.+)\\.nix$" name) != null)
          && (kind == "regular" || kind == "symlink")
          && (!isHidden name)
          && (name != "meta.nix")
        ) (readDir dir)
      );

      toName = fname: elemAt (match "^(.+)\\.nix$" fname) 0;

      all = map (file: {
        name = toName file;
        value = {
          top = dir;
          path = dir + "/${file}";
          name = toName file;
        };
      }) nixFiles;
    in
    if dirIgnored dir then { } else listToAttrs all;

  /**
    # `metaFileWithin`

    ```
      metaFileWithin :: (Path -> NullOr Path)
    ```

    Returns the found meta file path or null in the following order

    1. `meta.nix`
    2. `meta.toml`
    3. null
  */
  metaFileWithin =
    dir:
    if (pathExists (dir + "/meta.nix")) then
      (dir + "/meta.nix")
    else if (pathExists (dir + "/meta.toml")) then
      (dir + "/meta.toml")
    else
      null;

  /**
    # `discoverHybrid`

    ```
      discoverHybrid :: DiscoveryArgs -> { \${name} :: { name :: Attrs, path :: Path, meta :: Attrs, top :: Path } }
    ```

    Discovery function running on both files and subdirectories.

    (essentially a merge of discoverByFile & discover)
  */
  discoverHybrid =
    args@{
      inputs ? { },
      outputs ? { },
      modules ? [ ],
      extraSpecialArgs ? { },

      dir,
    }:
    let
      unlessIgnored = d: v: if dirIgnored d then { } else v;

      f = discoverByFile args;
      s = discover args;

      combined = f // s;
    in
    unlessIgnored dir combined;

  /**
    # `discoverByFile`

    ```
      discoverByFile :: DiscoveryArgs -> { \${name} :: { name :: String, path :: Path, meta :: Attrs, top :: Path } }
    ```

    Discovery function running towards just files
  */
  discoverByFile =
    {
      inputs ? { },
      outputs ? { },
      modules ? [ ],
      extraSpecialArgs ? { },

      dir,
    }:
    let
      metas = filter (x: !isNull x) (
        map deferMeta [
          (dir + "/meta.nix")
          (dir + "/meta.toml")
        ]
      );

      nixFiles = attrNames (
        filterAttrs (
          name: kind:
          ((match "^(.+)\\.nix$" name) != null)
          && (kind == "regular" || kind == "symlink")
          && (!isHidden name)
          && (name != "meta.nix")
        ) (readDir dir)
      );

      toName = fname: elemAt (match "^(.+)\\.nix$" fname) 0;

      all = map (file: {
        name = toName file;
        value = rec {
          top = dir;
          path = dir + "/${file}";
          name = toName file;
          meta =
            (evalMeta {
              inherit
                name
                inputs
                outputs
                extraSpecialArgs
                ;

              modules = modules ++ metas;
            }).config;
        };
      }) nixFiles;
    in
    if dirIgnored dir then { } else listToAttrs all;

  /**
    # `discover`

    ```
      discover :: DiscoveryArgs -> { \${name} :: { name :: String, path :: Path, modules :: Attrs, top :: Path } }
    ```

    The default discovery function, discovers by subdirectories
  */
  discover =
    {
      inputs ? { },
      outputs ? { },
      modules ? [ ],
      extraSpecialArgs ? { },

      dir,
    }:
    let
      topMetas = filter (x: !isNull x) (
        map deferMeta [
          (dir + "/meta.nix")
          (dir + "/meta.toml")
        ]
      );

      doPath =
        subdir: name:
        let
          metas = filter (x: !isNull x) (
            map deferMeta [
              (subdir + "/meta.nix")
              (subdir + "/meta.toml")
            ]
          );

          meta =
            (evalMeta {
              inherit
                name
                inputs
                outputs
                extraSpecialArgs
                ;

              modules = modules ++ topMetas ++ metas;
            }).config;
        in
        if dirIgnored subdir then
          null
        else
          {
            inherit name meta;
            path = subdir;
            top = dir;
          };

      found = map (name: {
        inherit name;
        path = dir + "/${name}";
      }) (filter (x: !isHidden x && !isNull x) (subdirNames dir));
    in
    if dirIgnored dir then
      { }
    else
      listToAttrs (
        filter (obj: obj.value != null) (
          map (
            {
              name,
              path,
            }:
            {
              inherit name;
              value = doPath path name;
            }
          ) found
        )
      );
}
