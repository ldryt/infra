{
  inputs,
  config,
  pkgs-unstable,
  ...
}:
{
  services.klipper = {
    enable = true;
    user = config.services.moonraker.user;
    group = config.services.moonraker.group;
    mutableConfig = true;
    mutableConfigFolder = config.services.moonraker.stateDir + "/config";
    configFile = ./VORON0.2_SKR_PICO_V1.0.cfg;
    logFile = config.services.moonraker.stateDir + "/logs/klippy.log";
  };

  security.polkit.enable = true;
  services.moonraker = {
    enable = true;
    allowSystemControl = true;
    settings = {
      authorization = {
        trusted_clients = [
          "0.0.0.0/0"
        ];
        cors_domains = [
          "https://printer.ldryt.dev"
        ];
      };
    };
  };

  networking.firewall.interfaces."domustunnel".allowedTCPPorts = [
    80
    9999
  ];
  services.mainsail.enable = true;

  imports = [ (inputs.nixpkgs-unstable + "/nixos/modules/services/video/ustreamer.nix") ];

  services.ustreamer = {
    enable = true;
    package = pkgs-unstable.ustreamer;
    listenAddress = "0.0.0.0:9999";
    extraArgs = [
      "--resolution=1024x768"
      "--quality=50"
      "--drop-same-frames=20"
      "--format=uyvy"
      # "--encoder=m2m-image"
      "--persistent"
      "--buffers=3"
      "--device-timeout=5"

      "--image-default"
      "--sharpness=80"
      "--brightness=55"
      "--contrast=5"
      "--saturation=5"
    ];
  };
}
