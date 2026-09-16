{ inputs, ... }:
let
  gruvbox-dark-theme = inputs.alacritty-gruvbox-dark.outPath;
in
{
  programs.alacritty = {
    enable = true;
    settings = {
      general.import = [ gruvbox-dark-theme ];
      font.size = 13;
    };
  };
}
