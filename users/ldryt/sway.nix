{ pkgs, ... }:
let
  swaylock-cfg = pkgs.writeText "swaylock-cfg" ''
    daemonize
    show-failed-attempts
    ignore-empty-password
    indicator-idle-visible
    indicator-radius=150
    color=000000
    ring-color=ffffff
    inside-ver-color=000000
  '';
  lock = "${pkgs.swaylock}/bin/swaylock --config=${swaylock-cfg}";
in
{
  imports = [
    ../commons/alacritty.nix
  ];

  home.packages = with pkgs; [
    slurp # screenshot utility
    grim
    swaybg # wallpaper utility
    wl-clipboard # clipboard utility
    clipman # clipboard manager
    bemenu # program launcher
    brightnessctl # screen brightness
  ];

  home.pointerCursor = {
    name = "Adwaita";
    package = pkgs.gnome.adwaita-icon-theme;
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

  services = {
    swayidle = {
      enable = true;
      events = [
        {
          event = "lock";
          command = lock;
        }
        {
          event = "before-sleep";
          command = lock;
        }
      ];
    };
    wlsunset = {
      enable = true;
      sunrise = "07:00";
      sunset = "20:00";
    };
  };

  wayland.windowManager.sway = {
    enable = true;
    checkConfig = true;
    config = null; # disable default config
    extraConfig = ''
      # set modifier (super key)
      set $mod Mod4

      # set font
      font pango:monospace 11

      # custom borders
      default_border pixel 1

      # lock the screen
      bindsym $mod+l exec ${lock}

      # start alacritty
      bindsym $mod+Return exec alacritty

      # kill focused window
      bindsym $mod+Shift+q kill

      # program launcher
      bindsym $mod+d exec bemenu-run

      # change focus
      bindsym $mod+Left focus left
      bindsym $mod+Down focus down
      bindsym $mod+Up focus up
      bindsym $mod+Right focus right

      # move focused window
      bindsym $mod+Shift+Left move left
      bindsym $mod+Shift+Down move down
      bindsym $mod+Shift+Up move up
      bindsym $mod+Shift+Right move right

      # split in horizontal orientation
      bindsym $mod+c split h

      # split in vertical orientation
      bindsym $mod+v split v

      # enter fullscreen mode for the focused container
      bindsym $mod+f fullscreen

      # change container layout (stacked, tabbed, toggle split)
      bindsym $mod+s layout stacking
      bindsym $mod+w layout tabbed
      bindsym $mod+e layout toggle split

      # toggle tiling / floating
      bindsym $mod+Shift+space floating toggle

      # change focus between tiling / floating windows
      bindsym $mod+space focus mode_toggle

      # focus the parent container
      bindsym $mod+a focus parent

      # focus the child container
      #bindsym $mod+d focus child

      # switch to workspace
      bindsym $mod+1 workspace 1
      bindsym $mod+2 workspace 2
      bindsym $mod+3 workspace 3
      bindsym $mod+4 workspace 4
      bindsym $mod+5 workspace 5
      bindsym $mod+6 workspace 6
      bindsym $mod+7 workspace 7
      bindsym $mod+8 workspace 8
      bindsym $mod+9 workspace 9

      # move focused container to workspace
      bindsym $mod+Shift+1 move container to workspace 1
      bindsym $mod+Shift+2 move container to workspace 2
      bindsym $mod+Shift+3 move container to workspace 3
      bindsym $mod+Shift+4 move container to workspace 4
      bindsym $mod+Shift+5 move container to workspace 5
      bindsym $mod+Shift+6 move container to workspace 6
      bindsym $mod+Shift+7 move container to workspace 7
      bindsym $mod+Shift+8 move container to workspace 8
      bindsym $mod+Shift+9 move container to workspace 9


      # reload the configuration file
      bindsym $mod+Shift+c reload
      # restart inplace
      bindsym $mod+Shift+r restart

      # adjust volume via pulseaudio
      bindsym --locked XF86AudioMute exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
      bindsym --locked XF86AudioLowerVolume exec wpctl set-volume @DEFAULT_SINK@ 5%-
      bindsym --locked XF86AudioRaiseVolume exec wpctl set-volume @DEFAULT_SINK@ 5%+

      # adjust brightness via brightnessctl
      bindsym --locked XF86MonBrightnessDown exec brightnessctl set 5%-
      bindsym --locked XF86MonBrightnessUp exec brightnessctl set 5%+

      # take a screenshot to clipboard
      bindsym Print exec grim -g "$(slurp)" - | wl-copy

      # set wallpaper using swaybg
      output "*" bg ${../commons/wallpaper.jpg} fill

      # HiDPi scaling for internal display
      output "eDP-1" scale 1.3
      output "eDP-1" scale_filter smart

      # touchpad tap-to-click and natural scrolling
      input type:touchpad {
        tap enabled
        natural_scroll enabled
      }

      # share clipboard content amongst windows
      exec wl-paste -t text --watch clipman store --no-persist

      # tell at a glance which windows are using Xwayland
      for_window [shell="xwayland"] title_format "[XWayland] %title"

      ## framework 13 color profile
      # output "*" color_profile icc ${./fw13.icm}

      bar {
        position bottom
        status_command i3status
      }
    '';
  };
}
