{ lib, config, pkgs, ... }:
{
  imports = [
    ./swaylock.nix
    ../common/alacritty.nix
  ];

  home.packages = with pkgs; [
    slurp # screenshot utilities
    grim
    swaybg # wallpaper utility
    wl-clipboard # clipboard utility
    clipman # clipboard manager
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

  programs = {
    i3status = {
      enable = true;
      enableDefault = false;
      general = {
        colors = false;
      };
      modules = {
        "time" = {
          position = 7;
          settings = {
            format = "%Y-%m-%d %H:%M";
          };
        };
        "memory" = {
          position = 6;
          settings = {
            format = "%free";
          };
        };
        "load" = {
          position = 5;
          settings = {
            format = "%5min";
          };
        };
        "disk /" = {
          position = 4;
          settings = {
            format = "%avail";
          };
        };
        "disk /nix" = {
          position = 3;
          settings = {
            format = "%avail";
          };
        };
        "battery all" = {
          position = 2;
          settings = {
            format = "%status %percentage";
            format_percentage = "%.f%s";
          };
        };
        "ethernet _first_" = {
          position = 1;
          settings = {
            format_up = "E: up";
            format_down = "E: down";
          };
        };
        "wireless _first_" = {
          position = 0;
          settings = {
            format_up = "W: %essid %quality";
            format_down = "W: down";
          };
        };
      };
    };
  };

  services.wlsunset = {
    enable = true;
    sunrise = "07:00";
    sunset = "20:00";
  };

  wayland.windowManager.sway = {
    enable = true;
    checkConfig = true;
    config = {
      modifier = "Mod4";
      terminal = "alacritty";
      window = {
        hideEdgeBorders = "both";
        border = 1;
      };
      keybindings = let
        mod = config.wayland.windowManager.sway.config.modifier;
      in lib.mkOptionDefault {
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
          scale = "1.3";
          scale_filter = "smart";
        };
      };
    };
  };
}
