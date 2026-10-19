{
  config,
  lib,
  inputs,
  burrow,
  ...
}:

let
  inherit (burrow.lib) evalMeta serializable;
  inherit (builtins) attrNames mapAttrs attrValues;
in
{
  flake.burrow = {
    builders = config.burrow.builders;
    manifest.builders = mapAttrs (name: builder: {
      inherit (builder) name;
      inherit (builder.meta) authors description outputs;
      search_paths = attrValues builder.searchPaths;
      template_path = builder.meta.templatePath;
      build_functions = attrNames builder.buildFunctions;
      aggregate_functions = attrNames builder.aggregateFunctions;
    }) config.flake.burrow.builders;
  };
}
