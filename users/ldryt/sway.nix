{
  lib,
  config,
  pkgs,
  ...
}:
let
  colorscheme = import ../common/i3/colors.nix;

  swaylock-cfg = pkgs.writeText "swaylock-cfg" ''
    daemonize
    show-failed-attempts
    ignore-empty-password
    indicator-idle-visible
    indicator-radius=120
    color=000000
    ring-color=ffffff
    inside-ver-color=000000
  '';
  lock-cmd = "playerctl pause ; ${pkgs.swaylock}/bin/swaylock --config=${swaylock-cfg}";
in
{
  imports = [
    ../common/foot.nix
    ../common/i3/i3status.nix
  ];

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
        timeout = 1 * 60;
        command = lock-cmd;
      }
      {
        timeout = 2 * 60;
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
  };

  services.wluma = {
    enable = true;
    settings = {
      als.iio = {
        path = "";
        thresholds = {
          "0" = "night";
          "20" = "dark";
          "250" = "normal";
          "500" = "bright";
          "80" = "dim";
          "800" = "outdoors";
        };
      };
    };
  };

  wayland.windowManager.sway = {
    enable = true;
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
          "XF86AudioMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ${wpctlToWob}";
          "XF86AudioLowerVolume" = "exec wpctl set-volume @DEFAULT_SINK@ 5%- ${wpctlToWob}";
          "XF86AudioRaiseVolume" = "exec wpctl set-volume @DEFAULT_SINK@ 5%+ ${wpctlToWob}";
          "XF86MonBrightnessDown" = "exec brightnessctl set 5%- ${brightnessctlToWob}";
          "XF86MonBrightnessUp" = "exec brightnessctl set 5%+ ${brightnessctlToWob}";
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
          scale = "1.25";
          scale_filter = "smart";
        };
      };
    };
  };
}
