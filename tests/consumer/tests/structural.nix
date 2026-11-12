{ nixt, flake, ... }:

let
  inherit (nixt.lib) block describe it;
in
block ./structural.nix [
  (describe "burrow/structure" [
    (it "Created a nixos configuration" (flake.nixosConfigurations ? test))
    (it "Created a home configuration" (flake.homeConfigurations ? test))
    (it "Created a module" (flake.nixosModules ? test))
  ])
]
