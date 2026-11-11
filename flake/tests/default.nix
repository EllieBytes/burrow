{ inputs, config, ... }:

let
  inherit (inputs) nixt;
  inherit (nixt.lib) grow;

  allTests = map (
    p:
    import p {
      inherit (config.flake) lib;
      inherit (inputs) nixt;
      inherit inputs;
    }
  );
in
{
  flake.__nixt = grow {
    blocks = allTests [
      ./helpers.nix
      ./files.nix
    ];
  };
}
