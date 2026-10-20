{ lib, self, ... }:

let
  inherit (lib) mapAttrs filterAttrs;
  inherit (self) deprioritize;
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
    ;

in
rec {
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
    # `discoverHybrid`

    ```
      discoverHybrid :: DiscoveryArgs -> { \${name} :: { name :: Attrs, path :: Path, meta :: Attrs, top :: Path } }
    ```

    Discovery function running on both files and subdirectories.

    (essentially a merge of discoverByFile & discover)
  */
  discoverHybrid = args@{
    inputs ? {},
    outputs ? {},
    modules ? [],
    extraSpecialArgs ? {},

    dir
  }:
  let
    ignored = d: pathExists (d + "/.burrow_skip");
    unlessIgnored = d: v: if ignored d then {} else v;

    f = discoverByFile args;
    s = discover args;

    combined = f // s;
  in unlessIgnored dir combined;

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
      ignored = d: pathExists (d + "/.burrow_skip");
      dlMeta = (if pathExists (dir + "/meta.nix") then import (dir + "/meta.nix") else { });

      nixFiles = attrNames (
        filterAttrs (
          name: kind: (match "^(.+)\\.nix$" != null) && (kind == "regular" || kind == "symlink") && (!isHidden name) && (name != "meta.nix")
        ) (readDir dir)
      );

      toName = fname: elemAt (match "^(.+)\\.nix$" fname) 0;

      all = map (file: {
        name = toName file;
        value = rec {
          top = dir;
          path = dir + "/${file}";
          name = toName file;
          meta = (evalMeta {
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
    if ignored dir then { } else listToAttrs all;

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
      ignored = d: pathExists (d + "/.burrow_skip");
      topLevel =
        if pathExists (dir + "/meta.nix") then
          deprioritize 500 (dir + "/meta.nix") (import (dir + "/meta.nix"))
        else
          { };

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
        if ignored subdir then
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
    if ignored dir then
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

  discovery.crawl = dir: {
    ignored = pathExists (dir + "/.burrow_skip");
    hasTopLevel = pathExists (dir + "/meta.nix");
    subdirs = (filter (x: !isHidden x) (subdirNames dir));
  };
}
