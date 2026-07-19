{ pkgs, ... }:
let
  swayConfig = pkgs.writeText "streaming-sway.conf" ''
    output HEADLESS-1 mode 2560x1440@60Hz
    default_border none
    exec "systemctl --user import-environment WAYLAND_DISPLAY; systemctl --user restart sunshine"
    exec steam-gamescope
  '';
  streamingSession = pkgs.writeShellScriptBin "streaming-session" ''
    export WLR_BACKENDS=headless,libinput
    export WLR_LIBINPUT_NO_DEVICES=1
    export WLR_RENDERER=gles2
    exec ${pkgs.sway}/bin/sway --unsupported-gpu --config ${swayConfig}
  '';
in
{
  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    nvidiaSettings = false;
  };
  services.xserver.videoDrivers = [ "nvidia" ];
  boot.blacklistedKernelModules = [
    "virtio_gpu"
    "bochs"
  ];

  users.users.ldryt.extraGroups = [
    "video"
    "render"
    "input"
  ];

  programs.steam = {
    enable = true;
    extraCompatPackages = [ pkgs.proton-ge-bin ];
    gamescopeSession = {
      enable = true;
      args = [
        "-W"
        "2560"
        "-H"
        "1440"
        "-f"
        "--backend"
        "wayland"
      ];
    };
  };

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${streamingSession}/bin/streaming-session";
        user = "ldryt";
      };
    };
  };

  services.sunshine = {
    enable = true;
    autoStart = false;
    openFirewall = true;
    package = pkgs.sunshine.override { cudaSupport = true; };
    settings = {
      capture = "wlr";
      # ssh -L 47990:localhost:47990 vidia -> https://localhost:47990
      origin_web_ui_allowed = "pc";
    };
  };
  systemd.user.services.sunshine.unitConfig.ConditionUser = "ldryt";

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    extraConfig.pipewire."10-stream-sink" = {
      "context.objects" = [
        {
          factory = "adapter";
          args = {
            "factory.name" = "support.null-audio-sink";
            "node.name" = "stream-sink";
            "media.class" = "Audio/Sink";
            "audio.position" = "FL,FR";
          };
        }
      ];
    };
  };
}
