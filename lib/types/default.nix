args@{ lib, ... }:

{
  types.builder = import ./builder.nix args;
  types.burrow = import ./burrow.nix args;

  types.searchPath = lib.types.nullOr (lib.types.either lib.types.path lib.types.str);
}
