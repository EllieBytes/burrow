{ lib, self, ... }:

let
  inherit (lib) mkOption types;
  inherit (types)
    attrsOf
    lazyAttrsOf
    listOf
    functionTo
    either
    ;
in
lib.types.submodule (
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
        description = ''
          Whether to enable builder: ${name}
        '';
      };

      name = mkOption {
        type = types.str;
        default = name;
        description = ''
          The name of this builder.
        '';
      };

      modules = mkOption {
        type = listOf types.deferredModule;
        default = [ ];
        description = ''
          Modules this builder passes to discovery functions.
          Usually to be evaluated before a `meta.nix` or `meta.toml` file.
        '';
      };

      settingsModules = mkOption {
        type = listOf types.deferredModule;
        default = [ ];
        description = ''
          Modules defining this builder's settings.
        '';
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

        description = ''
          The settings for this builder.
          Evaluated agains this builder's `settingsModules`.
        '';
      };

      searchPaths = mkOption {
        type = attrsOf (either types.str types.path);
        default = { };
        description = ''
          Attribute set of either absolute or relative paths to be searched by this builder's discovery function.
          Relative paths (contained in strings) are resolved against `burrow.root` in your flake config (if present).
        '';
      };

      specialArgs = mkOption {
        type = lazyAttrsOf types.anything;
        description = ''
          Special arguments for this builder, usually passed into a meta.nix evaluation.
        '';
      };

      buildFunctions = mkOption {
        type = lazyAttrsOf (functionTo types.attrs);
        default = { };
        description = ''
          Attribute set of build functions.
          These functions take in target contexts (the output of a discovery function). And produce structure to be merged into `config.flake`
        '';
      };

      aggregateFunctions = mkOption {
        type = lazyAttrsOf (functionTo types.attrs);
        default = { };
        description = ''
          Attribute set of aggregate functions.
          These functions take in the following structure.

          ```
            {
              outputs,    # Reference to the merged outputs built by all builders. (Note that flake outputs not managed by burrow do not appear here).
              discovered, # All Target Contexts found, separated as such <builder>.<object> = { /* Target Context */ }
            }
          ```
        '';
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
              outputs :: Attrs,          # Refers to output attrset.
              modules :: [Module],       # Raw modules from builder.
              extraSpecialArgs :: Attrs, # specialArgs from builder.
              dir :: Path                # current path to search.
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

          description = ''
            A description of this builder.
          '';
        };

        authors = mkOption {
          type = listOf types.str;
          default = [ ];
          description = ''
            A list of the authors of this builder.
          '';
        };

        templatePath = mkOption {
          type = types.path;
          default = ../assets/default_template;
          description = ''
            Absolute path to the default template for this builder's object.
          '';
        };

        outputs = mkOption {
          type = attrsOf types.str;
          default = { };
          description = ''
            Attribute set containing the expected output structure.
            [DEPRECATED!]
          '';
        };
      };
    };
  }
)
