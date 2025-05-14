{
  lib,
  config,
  pkgs,
  pkgs-unstable,
  inputs,
  ...
}:
let
  colorscheme = import ../common/i3/colors.nix;

  swaylock-cfg = pkgs.writeText "swaylock-cfg" ''
    daemonize
    show-failed-attempts
    indicator-idle-visible
    indicator-radius=120
    color=000000
    ring-color=ffffff
    inside-ver-color=000000
  '';
  lock-cmd = "\"playerctl pause ; ${pkgs.swaylock}/bin/swaylock --config=${swaylock-cfg}\"";
in
{
  imports = [
    ../common/foot.nix
    ../common/i3/i3status.nix

    (inputs.home-manager-unstable + "/modules/services/wluma.nix")
  ];

  # Portals configuration (used for e.g screensharing, theming)
  gtk.enable = true;
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
      xdg-desktop-portal-gtk
    ];
    config = {
      sway = {
        default = [
          "wlr"
          "gtk"
        ];
      };
    };
  };

  home.packages = with pkgs; [
    # Screenshots
    slurp
    grim
    # Wallpaper
    swaybg
    # Clipboard
    wl-clipboard
    clipman
    # Screen brightness
    brightnessctl
    # Control media players
    playerctl
  ];

  # Idle and locking management
  services.swayidle = {
    enable = true;
    extraArgs = [ "-d" ];
    events = [
    ];
    timeouts = [
      {
        timeout = 15 * 60;
        command = lock-cmd;
      }
      {
        timeout = 20 * 60;
        command = "cat /sys/class/power_supply/BAT1/status | grep -q 'Discharging' && systemctl suspend-then-hibernate";
      }
    ];
  };

  # Specify cursor
  home.pointerCursor = {
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 34;
    x11 = {
      enable = true;
      defaultCursor = "Adwaita";
    };
  };

  # A lightweight overlay volume/backlight/progress/anything bar
  services.wob.enable = true;

  # Command-line utility and library for controlling media players that implement MPRIS
  services.playerctld.enable = true;

  # Day/night gamma adjustments
  services.gammastep = {
    enable = true;
    enableVerboseLogging = true;
    provider = "geoclue2";
    # fallback
    latitude = 48.8;
    longitude = 2.3;
  };

  # Automatically switches dark-mode
  services.darkman = {
    enable = true;
    settings = {
      usegeoclue = true;
      # fallback
      lat = 48.8;
      lng = 2.3;
    };
    darkModeScripts = {
      gtk-theme = ''
        ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'"
      '';
    };
    lightModeScripts = {
      gtk-theme = ''
        ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/color-scheme "'prefer-light'"
      '';
    };
  };

  services.wluma = {
    enable = true;
    package = pkgs-unstable.wluma;
    settings = {
      als.iio = {
        path = "/sys/bus/iio/devices";
        thresholds = {
          "0" = "night";
          "20" = "dark";
          "250" = "normal";
          "500" = "bright";
          "80" = "dim";
          "800" = "outdoors";
        };
      };
      output = {
        backlight = [
          {
            name = "BOE 0x0BCA";
            path = "/sys/class/backlight/amdgpu_bl1";
            capturer = "wayland";
          }
          {
            name = "G3N0018101Q";
            path = "/sys/class/backlight/ddcci14";
            capturer = "wayland";
          }
        ];
      };
      keyboard = [
        {
          name = "framework-keyboard";
          path = "/sys/class/leds/framework_laptop::kbd_backlight";
        }
      ];
    };
  };

  wayland.windowManager.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    checkConfig = true;
    extraConfig = ''
      # No titlebars
      default_border none
      default_floating_border none
      font pango:monospace 0.001
      titlebar_padding 1
      titlebar_border_thickness 0
    '';
    config = {
      bars = [
        {
          statusCommand = "${pkgs.i3status}/bin/i3status";
          colors = colorscheme.bar;
        }
      ];
      colors = colorscheme.client;
      modifier = "Mod4";
      terminal = "foot";
      keybindings =
        let
          mod = config.wayland.windowManager.sway.config.modifier;
          wobSocket = "$XDG_RUNTIME_DIR/wob.sock";
          wpctlToWob = "&& wpctl get-volume @DEFAULT_SINK@ | awk '/\[MUTED\]/ {print 0; next} {print int($2 * 100)}' > ${wobSocket}";
          brightnessctlToWob = "| awk '/Current brightness:/ { print int($3 / 255 * 100)}' > ${wobSocket}";
        in
        lib.mkOptionDefault {
          "${mod}+d" = "exec ${pkgs.dmenu-wayland}/bin/dmenu-wl_run";
          "${mod}+f" = "fullscreen";
          "${mod}+l" = "exec ${lock-cmd}";
          "XF86AudioPlay" = "exec playerctl play-pause";
          "XF86AudioNext" = "exec playerctl next";
          "XF86AudioPrev" = "exec playerctl previous";
          "XF86AudioMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ${wpctlToWob}";
          "XF86AudioLowerVolume" = "exec wpctl set-volume @DEFAULT_SINK@ 5%- ${wpctlToWob}";
          "XF86AudioRaiseVolume" = "exec wpctl set-volume @DEFAULT_SINK@ 5%+ ${wpctlToWob}";
          "XF86MonBrightnessDown" = "exec brightnessctl set 5%- ${brightnessctlToWob}";
          "XF86MonBrightnessUp" = "exec brightnessctl set 5%+ ${brightnessctlToWob}";
          "Print" = "exec grim -g \"$(slurp)\" - | wl-copy";
        };
      startup = [
        { command = "${pkgs.sway-audio-idle-inhibit}/bin/sway-audio-idle-inhibit"; }
      ];
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
          scale = "1.25";
          scale_filter = "smart";
        };
      };
    };
  };
}
