{
  burrow,
  config,
  lib,
  ...
}:

let
  inherit (builtins) pathExists;
  inherit (burrow.lib.fs) allPresent intoPaths;

  mkHome =
    {
      meta,
      path,
      ...
    }:
    let
      foundModules = intoPaths (allPresent meta.files path) path;
    in
    meta.advanced.homeFn {
      inherit (meta)
        pkgs
        extraSpecialArgs
        minimal
        lib
        ;

      modules = [
        ({ lib, ... }: {
          home.username = lib.mkDefault meta.username;
          home.homeDirectory = lib.mkDefault meta.homeDirectory;
        })
        (if pathExists (path + "/home.nix") then (path + "/home.nix") else { })
      ]
      ++ foundModules
      ++ meta.extraModules;
    };
in
{
  burrow.builders.home = {
    modules = [ ./modules ];

    searchPaths = lib.mkDefault {
      home = "home";
      users = "users";
      homeConfigurations = "homeConfigurations";
    };

    extraSpecialArgs = {
      pkgsFor = config.burrow.pkgs;
    };

    buildFunctions.home =
      args@{
        meta,
        ...
      }:
      {
        homeConfigurations."${meta.name}" = mkHome args;
      };
  };
}
