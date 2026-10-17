{ burrow, ... }:

let
  inherit (builtins) attrNames readDir;
in
{
  imports = map (x: ./builders + "/${x}") (attrNames (readDir ./builders));
  flake = burrow.build { };
}
