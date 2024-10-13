{ pkgs, ... }:
let
  gruvbox-dark-theme = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/alacritty/alacritty-theme/refs/heads/master/themes/gruvbox_dark.toml";
    hash = "sha256-hdperHMsuJugodM0IyueJV6QH0l40+XrVRKnHRQRbqc=";
  };
in
{
  programs.alacritty = {
    enable = true;
    settings = {
      import = [ gruvbox-dark-theme ];
      font.size = 13;
    };
  };
}
