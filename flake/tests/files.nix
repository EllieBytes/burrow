{
  nixt,
  lib,
  ...
}:

let
  inherit (nixt.lib) block describe it;
  inherit (lib.fs) intoPaths allPresent;
in
block ./files.nix [
  (describe "burrow/fs" [
    (it "intoPaths is sane" (
      (intoPaths [
        "2metas"
        "skip"
      ] ./static) == [
        ./static/2metas
        ./static/skip
      ]
    ))

    (it "allPresent functions with only present paths" (
      (allPresent [ "2metas" "skip" ] ./static) == [
        "2metas"
        "skip"
      ]
    ))

    (it "allPresent functions with no present paths" (
      (allPresent [ "null" "notexists" ] ./static) == [ ]
    ))

    (it "allPresent functions with mixed paths" (
      (allPresent [ "2metas" "null" ] ./static) == [ "2metas" ]
    ))
  ])
]
