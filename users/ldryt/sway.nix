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
  ];

  # Idle and locking management
  services.swayidle = {
    enable = true;
    extraArgs = [ "-d" ];
    events = [
    ];
    timeouts = [
      {
        timeout = 5;
        command = "echo 1 >> /tmp/timeouttt";
      }
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

  # A lightweight overlay volume/backlight/progress/anything bar
  services.wob.enable = true;

  # Command-line utility and library for controlling media players that implement MPRIS
  services.playerctld.enable = true;

  # Day/night gamma adjustments
  services.wlsunset = {
    enable = true;
    latitude = 48.8;
    longitude = 2.3;
  };

  wayland.windowManager.sway = {
    enable = true;
    checkConfig = true;
    extraConfigEarly = ''
      # No titlebars
      default_border none
      default_border normal 0
      default_floating_border normal 0
      for_window [title="^.*"] title_format ""
    '';
    config = {
      window = {
        hideEdgeBorders = "both";
        border = 1;
      };
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
