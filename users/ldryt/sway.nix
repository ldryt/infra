{
  lib,
  pkgs,
  pkgs-unstable,
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
    hide-keyboard-layout
  '';
  lock-cmd = "${pkgs.playerctl}/bin/playerctl pause ; ${pkgs.swaylock}/bin/swaylock --config=${swaylock-cfg}";
in
{
  imports = [
    ../common/i3/i3status.nix
  ];

  home.packages = with pkgs; [
    # Screenshots
    slurp
    grim
    wf-recorder
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
      {
        event = "before-sleep";
        command = lock-cmd;
      }
      {
        event = "lock";
        command = lock-cmd;
      }
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

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "x-scheme-handler/about" = "firefox.desktop";
      "x-scheme-handler/unknown" = "firefox.desktop";
    };
  };

  programs.ghostty = {
    enable = true;
    enableBashIntegration = true;
    settings = {
      theme = "dark:GitLab Dark,light:GitLab Light";
      confirm-close-surface = false;
      resize-overlay = "never";
      app-notifications = false;
    };
  };

  gtk.enable = true;
  qt.enable = true;
  wayland.windowManager.sway =
    let
      mod = "Mod4";
    in
    {
      enable = true;
      checkConfig = false;
      wrapperFeatures.gtk = true;
      extraSessionCommands = ''
        export SDL_VIDEODRIVER="wayland,x11,windows"
        export QT_QPA_PLATFORM="wayland;xcb"
        export GDK_BACKEND="wayland,x11,*"
        export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
        # Fix for some Java AWT applications
        export _JAVA_AWT_WM_NONREPARENTING=1
        # Vulkan for ICC color profile
        export WLR_RENDERER=vulkan
      '';
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
        modifier = mod;
        terminal = "${pkgs.ghostty}/bin/ghostty";
        keybindings =
          let
            wobSocket = "$XDG_RUNTIME_DIR/wob.sock";
            wpctlToWob = "&& wpctl get-volume @DEFAULT_SINK@ | awk '/\[MUTED\]/ {print 0; next} {print int($2 * 100)}' > ${wobSocket}";
            brightnessctlToWob = "| awk '/Current brightness:/ { print int($3 / 255 * 100)}' > ${wobSocket}";
          in
          lib.mkOptionDefault {
            "${mod}+d" = "exec ${pkgs.dmenu-wayland}/bin/dmenu-wl_run";
            "${mod}+f" = "fullscreen";
            "${mod}+l" = "exec \"${lock-cmd}\"";
            "XF86AudioPlay" = "exec playerctl play-pause";
            "XF86AudioNext" = "exec playerctl next";
            "XF86AudioPrev" = "exec playerctl previous";
            "XF86AudioMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ${wpctlToWob}";
            "XF86AudioLowerVolume" = "exec wpctl set-volume @DEFAULT_SINK@ 5%- ${wpctlToWob}";
            "XF86AudioRaiseVolume" = "exec wpctl set-volume @DEFAULT_SINK@ 5%+ ${wpctlToWob}";
            "XF86MonBrightnessDown" = "exec brightnessctl set 5%- ${brightnessctlToWob}";
            "XF86MonBrightnessUp" = "exec brightnessctl set 5%+ ${brightnessctlToWob}";
            "Print" =
              "exec grim -g \"$(slurp)\" - | tee ~/Pictures/Screenshots/screenshot_\"$(date +'%Y-%m-%d_%H:%M:%S')_$(hostname)\".jpg | wl-copy";
            "Ctrl+Print" =
              "exec sh -c 'kill -2 $(pidof wf-recorder) || { test ! $? -eq 0 && wf-recorder -g \"$(slurp)\" --audio=\"$(pactl info | grep \"Default Sink\" | cut -d \" \" -f3)\".monitor -f ~/Pictures/Screenshots/recording_\"$(date +'%Y-%m-%d_%H:%M:%S')_$(hostname)\".mp4; }'";
          };
        startup = [
          {
            # https://archive.is/CDQxh
            command = "systemctl --user import-environment PATH && systemctl --user restart xdg-desktop-portal.service";
          }
          { command = "${pkgs.sway-audio-idle-inhibit}/bin/sway-audio-idle-inhibit"; }
        ];
        input = {
          "type:touchpad" = {
            tap = "enabled";
            natural_scroll = "enabled";
          };
          "type:keyboard" = {
            xkb_layout = "qwerty-fr,us,fr";
          };
        };
        output = {
          "*" = {
            bg = "${../common/wallpaper.jpg} fill";
          };
          "eDP-1" = {
            scale = "1";
            color_profile = "icc ${./BOE_CQ_______NE135FBM_N41_03.icm}";
          };
        };
      };
    };
}
