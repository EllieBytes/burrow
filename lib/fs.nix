{ lib, ... }:

let
  inherit (builtins)
    attrNames
    match
    readDir
    elem
    ;

  inherit (lib) filterAttrs;
in
{
  /**
    # `intoPaths`

    ```
      intoPaths :: [ String ] -> Path -> [ Path ]
    ```

    Resolves a list of relative paths against an absolute path.
  */
  fs.intoPaths = names: baseDir: map (name: baseDir + "/${name}") names;

  /**
    # `isHidden`

    ```
      isHidden :: String -> Bool
    ```

    Determines whether a file name is hidden.
  */
  fs.isHidden = name: (match "^\\..*" name) != null;

  /**
    # `subdirNames`

    ```
      subdirNames :: Path -> [ String ]
    ```

    Gathers the names of all subdirectories of a directory.
  */
  fs.subdirNames = dir: attrNames (filterAttrs (_: kind: kind == "directory") (readDir dir));

  /**
    # `dirName`

    ```
      dirName :: Path -> String
    ```

    Gets the directory name of an absolute path.
  */
  fs.dirName = dir: baseNameOf (toString dir);

  /**
    # `allPresent`

    ```
      allPresent :: [ String ] -> Path -> [ String ]
    ```

    Resolves all relative paths against an absolute path and returns all names that exist.
  */
  fs.allPresent = names: dir: attrNames (filterAttrs (name: _: elem name names) (readDir dir));
}
