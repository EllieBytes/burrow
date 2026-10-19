{
  description = "NixOS with burrow";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05"; # Required for NixOS
  inputs.flake-parts.url = "github:hercules-ci/flake-parts"; # Required for Burrow.
  inputs.burrow.url = "github:EllieBytes/burrow";

  outputs =
    inputs@{ flake-parts, burrow, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        burrow.flakeModule
      ];

      # Setting this allows the builtin nixos builder to find paths automatically.
      # The default search paths for the builtin nixos builder are:
      # - hosts/
      # - nixos/
      # - nixosConfigurations/
      # - systems/
      burrow.root = ./.;
    };
}
