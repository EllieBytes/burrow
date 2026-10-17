{
  lib,
  extend ? true,
}:

let
  ignore = [ "default.nix" ];

  inherit (builtins)
    attrNames
    elem
    filter
    foldl'
    readDir
    ;

  files = map (p: ./. + "/${p}") (filter (x: !elem x ignore) (attrNames (readDir ./.)));
in
if extend then
  lib.recursiveUpdate lib (
    lib.extend (
      final: prev:
      foldl' lib.recursiveUpdate { } (
        map (
          p:
          import p {
            self = final;
            lib = final;
          }
        ) files
      )
    )
  )
else
  lib.fix (self: foldl' lib.recursiveUpdate { } (map (p: import p { inherit lib self; }) files))
