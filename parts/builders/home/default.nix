{ lib, ... }:

let
  inherit (builtins) pathExists match elemAt;

  re = "^([a-zA-Z0-9._%+-]+)@([a-zA-Z0-9\\..-]+)";

  isBound = name: (match re name) != null;
  splitBound =
    name:
    assert isBound name;
    let
      split = match re name;
    in
    {
      name = elemAt split 0;
      host = elemAt split 0;
    };
in
{
  burrow.builders.home = {
    modules = [ ./modules ];

    buildFunctions.home =
      {
        meta,
        path,
        ...
      }:
      {
        homeConfigurations."${meta.name}" = meta.advanced.homeFn {
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
          ++ meta.extraModules;
        };
      };

    buildFunctions.unbounded =
      {
        meta,
        path,
        ...
      }:
      let
        base = (if isBound meta.name then (splitBound meta.name).name else meta.name);
        named = map (host: "${base}@${host}") meta.buildForHosts;
      in
      {
        homeConfigurations = lib.genAttrs named (
          meta.home-manager.lib.homeManagerConfiguration {
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
            ++ meta.extraModules;
          }
        );
      };
  };
}
