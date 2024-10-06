{ ... }:
{
  dconf = {
    enable = true;
    settings = {
      "org/gnome/desktop/peripherals/touchpad" = {
        tap-to-click = true;
        two-finger-scrolling-enabled = true;
      };
      "org/gnome/desktop/interface" = {
        text-scaling-factor = 1.25;
        color-scheme = "prefer-dark";
        enable-hot-corners = true;
      };
      "org/gnome/mutter" = {
        edge-tiling = true;
        dynamic-workspaces = true;
      };
      "org/gnome/desktop/search-providers" = {
        disabled = [
          "org.gnome.clocks.desktop"
          "org.gnome.Characters.desktop"
        ];
      };
      "org/gnome/desktop/sound" = {
        event-sounds = false;
      };
      "org/gnome/settings-daemon/plugins/power" = {
        power-button-action = "hibernate";
      };
      "org/gnome/shell" = {
        enabled-extensions = [ "launch-new-instance@gnome-shell-extensions.gcampax.github.com" ];
        favorite-apps = [
          "org.gnome.Nautilus.desktop"
          "org.gnome.Console.desktop"
          "firefox.desktop"
          "thunderbird.desktop"
          "org.gnome.Calculator.desktop"
          "org.gnome.TextEditor.desktop"
        ];
      };
      "org/gnome/desktop/background" = {
        picture-uri = "file://" + ./wallpaper.jpg;
        picture-uri-dark = "file://" + ./wallpaper.jpg;
      };
      "org/gnome/desktop/screensaver" = {
        picture-uri = "file://" + ./wallpaper.jpg;
        primary-color = "#191724";
        secondary-color = "#000000";
      };
      "org/gnome/desktop/wm/keybindings" = {
        toggle-fullscreen = [ "<Super>f" ];
        switch-applications = [ ];
        switch-windows = [ "<Alt>Tab" ];
      };
    };
  };
}
