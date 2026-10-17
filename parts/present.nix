{
  config,
  lib,
  inputs,
  burrow,
  ...
}:

let
  inherit (burrow.lib) evalMeta serializable;
  inherit (builtins) attrNames mapAttrs;
in
{
  flake.burrow = {
    builders = config.burrow.builders;
    manifest.builders = mapAttrs (name: builder: {
      inherit (builder) name;
      inherit (builder.meta) authors description outputs;
      template_path = builder.meta.templatePath;
      build_functions = attrNames builder.buildFunctions;
      aggregate_functions = attrNames builder.aggregateFunctions;
      builder_opts =
        (evalMeta {
          inherit inputs;
          inherit (builder) name modules;
          outputs = config.flake;
          extraSpecialArgs = builder.specialArgs;
        }).options;
    }) config.flake.burrow.builders;
  };
}
