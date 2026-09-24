{ inputs, config, ... }:
let
  gruvbox-dark-theme = "${inputs.alacritty-theme}/themes/gruvbox_dark.toml";
  gruvbox-light-theme = "${inputs.alacritty-theme}/themes/gruvbox_light.toml";
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
