{ lib, self, ... }:

let
  inherit (lib) mkOption types;
  inherit (types)
    attrsOf
    submodule
    lazyAttrsOf
    listOf
    functionTo
    either
    ;
in
{
  types.builder = submodule (
    {
      config,
      name ? "",
      ...
    }:
    {
      options = {
        enable = mkOption {
          type = types.bool;
          default = true;
          example = false;
        };

        name = mkOption {
          type = types.str;
          default = name;
        };

        modules = mkOption {
          type = listOf types.deferredModule;
          default = [ ];
        };

        settingsModules = mkOption {
          type = listOf types.deferredModule;
          default = [ ];
        };

        settings = mkOption {
          type = types.deferredModule;
          default = { };
          apply = (
            value:
            (lib.evalModules {
              modules = config.settingsModules ++ [ value ];
            }).config
          );
        };

        searchPaths = mkOption {
          type = attrsOf (either types.str types.path);
          default = { };
        };

        specialArgs = mkOption {
          type = lazyAttrsOf types.anything;
        };

        buildFunctions = mkOption {
          type = lazyAttrsOf (functionTo types.attrs);
          default = { };
        };

        aggregateFunctions = mkOption {
          type = lazyAttrsOf (functionTo types.attrs);
          default = { };
        };

        extraSpecialArgs = mkOption {
          type = lazyAttrsOf types.unspecified;
          default = { };
          description = ''
            Extra args to pass to meta.nix files.
          '';
        };

        discoveryFunction = mkOption {
          type = functionTo (types.attrs);
          default = self.discover;
          description = ''
            The function used to discover this builder's inputs.
            You will likely never need to change this.
            NOTE:
              The function here MUST be typed as shown below.
              The builder will error out if it does not.

              Here is the required signature.

              ```Nix
              discoveryFunction :: {
                inputs  :: Attrs,          # Flake inputs
                outputs :: Attrs,          # Refers to config.flake
                modules :: [Module],       # Raw modules from builder
                extraSpecialArgs :: Attrs, # specialArgs from builder
                dir :: Path                # current path to search
              } -> (AttrsOf Attrs) # { <name> = <buildContext> } for everything discovered.
              ```

              Another thing to note. the outputs are your build context.
              These are passed directly into build functions.
          '';
        };

        meta = {
          description = mkOption {
            type = types.str;
            default = ''
              This builder does not provide a description.
            '';
          };

          authors = mkOption {
            type = listOf types.str;
            default = [ ];
          };

          templatePath = mkOption {
            type = types.path;
            default = ../assets/default_template;
          };

          outputs = mkOption {
            type = attrsOf types.str;
            default = { };
          };
        };
      };
    }
  );
}
