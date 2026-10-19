{ lib, self, ... }:

let
  inherit (lib) mapAttrs;
  inherit (self) deprioritize;
  inherit (self.fs) isHidden subdirNames;

  inherit (builtins)
    filter
    listToAttrs
    pathExists
    warn
    filterAttrs
    match
    readDir
    elemAt
    attrNames
    ;

in
rec {
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
      meta = (if pathExists (dir + "/meta.nix") then import (dir + "/meta.nix") else { });

      nixFiles = attrNames (
        filterAttrs (
          name: kind: (match "^(.+)\\.nix$" != null) && (kind == "regular" || kind == "symlink")
        ) (readDir dir)
      );

      toName = fname: elemAt (match "^(.+)\\.nix$") 0;

      all = map (file: {
        name = toName file;
        value = rec {
          top = dir;
          path = dir + "/${file}";
          name = toName file;
          meta = evalMeta {
            inherit
              name
              inputs
              outputs
              extraSpecialArgs
              ;

            modules = modules ++ [ meta ];
          };
        };
      }) nixFiles;
    in
    if ignored dir then { } else listToAttrs all;

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
          };

      found = map (name: {
        inherit name;
        path = dir + "/${name}";
      }) (filter (x: !isHidden x) (subdirNames dir));
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
