{ pkgs, config, ... }:
let
  gruvbox-dark-theme = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/alacritty/alacritty-theme/refs/heads/master/themes/gruvbox_dark.toml";
    hash = "sha256-hdperHMsuJugodM0IyueJV6QH0l40+XrVRKnHRQRbqc=";
  };
  gruvbox-light-theme = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/alacritty/alacritty-theme/refs/heads/master/themes/gruvbox_light.toml";
    hash = "sha256-7jwcsFzo7mVe6kUZLXYolUy9pWKtTMO19KOMQM13ZYY=";
  };
in
{
  # from https://github.com/alacritty/alacritty/issues/5999#issuecomment-2367121745
  services.darkman = {
    enable = true;
    darkModeScripts = {
      alacritty-theme = ''
        ln -fs ${gruvbox-dark-theme} ${config.xdg.configHome}/alacritty/_active.toml
      '';
    };
    lightModeScripts = {
      alacritty-theme = ''
        ln -fs ${gruvbox-light-theme} ${config.xdg.configHome}/alacritty/_active.toml
      '';
    };
    settings = {
      lat = 48.8;
      lng = 2.3;
    };
  };
}
