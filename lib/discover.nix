{ lib, self, ... }:

let
  inherit (lib) filterAttrs;
  inherit (self.fs) isHidden subdirNames;

  inherit (builtins)
    filter
    listToAttrs
    pathExists
    warn
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
      deferMeta :: Path -> DeferredModule
    ```

    Accepts a path to a Nix or TOML file (The two accepted meta formats).
    Loads whichever it finds.

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
    if ext == "nix" then
      (import file)
    else if ext == "toml" || ext then
      (fromTOML (readFile file))
    else
      throw "Invalid meta extension, expected *.nix | *.toml got .${ext}";

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
      dlMeta = (if pathExists (dir + "/meta.nix") then import (dir + "/meta.nix") else { });

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

              modules = modules ++ [ dlMeta ];
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
      topLevel = if pathExists (dir + "/meta.nix") then (import (dir + "/meta.nix")) else { };

      doPath =
        subdir: name:
        let
          found =
            if pathExists (subdir + "/meta.nix") then
              import (subdir + "/meta.nix")
            else
              warn "No meta.nix found for item ${name} at ${subdir}" { };

          meta =
            (evalMeta {
              inherit
                name
                inputs
                outputs
                extraSpecialArgs
                ;

              modules = modules ++ [
                topLevel
                found
              ];
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
