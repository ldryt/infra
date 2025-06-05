{ config, ... }:
{
  services.klipper = {
    enable = true;
    user = config.services.moonraker.user;
    group = config.services.moonraker.group;
    mutableConfig = true;
    configDir = config.services.moonraker.stateDir + "/config";
    configFile = ./VORON0.2_SKR_PICO_V1.0.cfg;
    logFile = config.services.moonraker.stateDir + "/logs/klippy.log";
  };

  # Add package 'klipper-firmware-*' to system packages
  services.klipper.firmwares."SKR_PICO_V1.0" = {
    enable = true;
    enableKlipperFlash = true;
    serial = "/dev/null"; # can't flash this mcu

    # To get this config file, run package 'klipper-genconf'
    # (make sure version match with pkgs.klipper)
    configFile = ./SKR_PICO_V1.0__firmware.env;
  };

  sops.secrets."services/moonraker/secrets" = {
    owner = config.services.moonraker.user;
    path = config.services.moonraker.stateDir + "/moonraker.secrets";
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
      "power Power_Supply" = {
        type = "homeassistant";
        protocol = "https";
        address = "domus.ldryt.dev";
        port = "443";
        device = "switch.printer";
        token = "{secrets.home_assistant.token}";
        off_when_shutdown = true;
        locked_while_printing = true;
        restart_klipper_when_powered = true;
        restart_delay = 3;
      };
    };
  };

  networking.firewall.interfaces."domustunnel".allowedTCPPorts = [
    80
    9999
  ];
  services.mainsail.enable = true;

  services.ustreamer = {
    enable = true;
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
