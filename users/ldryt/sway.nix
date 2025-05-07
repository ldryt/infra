{
  lib,
  config,
  pkgs,
  ...
}:
let
  colorscheme = import ../common/i3/colors.nix;
in
{
  imports = [
    ./swaylock.nix
    ../common/foot.nix
    ../common/i3/i3status.nix
  ];

  home.packages = with pkgs; [
    slurp
    grim
    swaybg
    wl-clipboard
    clipmam
  ];

  home.pointerCursor = {
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 34;
    x11 = {
      enable = true;
      defaultCursor = "Adwaita";
    };
  };

  services.wlsunset = {
    enable = true;
    latitude = 48.8;
    longitude = 2.3;
  };

  wayland.windowManager.sway = {
    enable = true;
    checkConfig = true;
    config = {
      modifier = "Mod4";
      terminal = "foot";
      window = {
        hideEdgeBorders = "both";
        border = 1;
      };
      keybindings =
        let
          mod = config.wayland.windowManager.sway.config.modifier;
        in
        lib.mkOptionDefault {
          "${mod}+d" = "exec ${pkgs.dmenu-wayland}/bin/dmenu-wl_run";

          "${mod}+f" = "fullscreen";

          "XF86AudioMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          "XF86AudioLowerVolume" = "exec wpctl set-volume @DEFAULT_SINK@ 5%-";
          "XF86AudioRaiseVolume" = "exec wpctl set-volume @DEFAULT_SINK@ 5%+";

          "XF86MonBrightnessDown" = "exec ${pkgs.brightnessctl}/bin/brightnessctl set 5%-";
          "XF86MonBrightnessUp" = "exec ${pkgs.brightnessctl}/bin/brightnessctl set 5%+";

          "Print" = "exec grim -g \"$(slurp)\" - | wl-copy";
        };
      input = {
        "type:touchpad" = {
          tap = "enabled";
          natural_scroll = "enabled";
        };
      };
      output = {
        "*" = {
          bg = "${../common/wallpaper.jpg} fill";
        };
        "eDP-1" = {
          scale = "1.33";
          scale_filter = "smart";
        };
      };
      bars = [
        {
          statusCommand = "${pkgs.i3status}/bin/i3status";
          colors = colorscheme.bar;
        }
      ];
      colors = colorscheme.client;
    };
  };
}
