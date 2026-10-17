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
  fs.intoPaths = names: baseDir: map (name: baseDir + "/${name}") names;
  fs.isHidden = name: (match "^\\..*" name) == [ ];
  fs.subdirNames = dir: attrNames (filterAttrs (_: kind: kind == "directory") (readDir dir));
  fs.dirName = dir: baseNameOf (toString dir);
  fs.allPresent = names: dir: attrNames (filterAttrs (name: _: elem name names) (readDir dir));
}
