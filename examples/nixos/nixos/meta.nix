# This file is evaluated before each host.
# NOTE: This file's priority is lowered to 500 by Burrow.
#       This means that anything declared here (without mkForce/mkOverride) may be overriden.
{
  extraModules = [
    ../modules
  ];
}
