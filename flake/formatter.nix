{
  perSystem = { ... }: {
    treefmt = {
      programs.nixfmt.enable = true;
      programs.beautysh.enable = true;
    };
  };
}
