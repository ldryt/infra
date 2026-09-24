{ inputs, ... }:
let
  gruvbox-dark-theme = "${inputs.alacritty-theme}/themes/gruvbox_dark.toml";
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
