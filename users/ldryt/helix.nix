{ ... }: {
  home.sessionVariables.EDITOR = "hx";
  home.shellAliases."vim" = "hx";

  programs.helix = {
    enable = true;
    settings = {
      editor = {
        mouse = false;
        auto-pairs = false;
        soft-wrap.enable = true;
        cursor-shape = { insert = "bar"; };
      };
      theme = "fleet_dark";
    };
    languages = {
      language = [
        {
          name = "rust";
          formatter.command = "rustfmt";
        }
        {
          name = "nix";
          formatter.command = "nixfmt";
          auto-format = true;
        }
      ];
    };
  };
}
