{
  nixt,
  lib,
  ...
}:

let
  inherit (nixt.lib) block describe it;
  inherit (lib) fs;

  testSerAttrs = {
    func = (_: { });
    list = [
      "str"
      null
      (_: 0)
    ];

    attrs = {
      norm = "hi";
      func = (_: 0);
      nil = null;
    };

    nil = null;
    norm = "a";
  };

  testSerExpected = {
    func = "<function>";
    list = [
      "str"
      ""
      "<function>"
    ];

    attrs = {
      norm = "hi";
      func = "<function>";
      nil = "";
    };

    nil = "";
    norm = "a";
  };
in
block ./helpers.nix [
  (describe "burrow/misc" [
    (it "Discerns hidden names" ((fs.isHidden ".hidden") && !(fs.isHidden "not-hidden")))
    (it "Properly prepares values for JSON evals" ((lib.serializable testSerAttrs) == testSerExpected))
    (it "can ignore a directory if `.burrow_skip` exists" (lib.dirIgnored ./static/skip))
  ])
]
