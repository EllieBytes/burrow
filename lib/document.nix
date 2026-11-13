{ lib, self, ... }:

let
  inherit (lib) mapAttrs;
in
{
  /**
    # `document`

    ```
      document :: Attrs -> Burrow -> Attrs -> String -> Derivation
    ```

    Documents the meta options for all builders in a burrow.
  */
  document =
    outputs: burrow: args: system:
    let
      docBuilder =
        builder:
        let
          eval = self.evalMeta {
            inherit (builder) modules;
            extraSpecialArgs = builder.extraSpecialArgs // args;
            inherit outputs;
          };

          doc = burrow.pkgs."${system}".nixosOptionsDoc {
            inherit (eval) options;
          };
        in
        doc.optionsCommonMark;

      builderDocs = mapAttrs (_: builder: (docBuilder builder)) burrow.builders;
    in
    builderDocs;
}
