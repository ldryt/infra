{ config, ... }:
{
  imports = [
    # ./tunnel.nix
    ../../../../modules/mdns-publish.nix
  ];

  environment.persistence.printer.directories = [
    {
      directory = config.services.moonraker.stateDir;
      user = config.services.moonraker.user;
      group = config.services.moonraker.group;
      mode = "0700";
    }
  ];

  networking.firewall.allowedTCPPorts = [
    80
    9999
  ];

  services.klipper = {
    enable = true;
    user = config.services.moonraker.user;
    group = config.services.moonraker.group;
    configDir = config.services.moonraker.stateDir + "/config";
    configFile = ./VORON0.2_SKR_PICO_V1.0.cfg;
    logFile = config.services.moonraker.stateDir + "/logs/klippy.log";
  };
  systemd.tmpfiles.rules = [
    "f ${config.services.klipper.logFile} 0600 ${config.services.klipper.user} ${config.services.klipper.group}"
  ];

  services.mainsail.enable = true;

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
          "http://printer.local"
          #   "https://printer.ldryt.dev"
        ];
      };
      # "power Power_Supply" = {
      #   type = "homeassistant";
      #   protocol = "https";
      #   address = "domus.ldryt.dev";
      #   port = "443";
      #   device = "switch.printer";
      #   token = "{secrets.home_assistant.token}";
      #   off_when_shutdown = true;
      #   locked_while_printing = true;
      #   restart_klipper_when_powered = true;
      #   restart_delay = 3;
      # };
    };
  };

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

  # Add packages 'klipper-firmware-*' to system packages
  services.klipper.firmwares = {
    "SKR_PICO_V1.0" = {
      enable = true;
      enableKlipperFlash = true;

      serial = "/dev/null"; # can't flash this mcu

      # To flash:
      # 1. Boot pin jumper on mcu
      # 2. $ klipper-flash-SKR_PICO_V1.0
      # 3. Copy klipper.uf2 from path given by step 2 into mounted mcu
      # 4. mcu should reboot automatically
      # 5. Remove boot pin jumper on mcu

      # To get this config file, run package 'klipper-genconf'
      # (make sure version match with pkgs.klipper)
      configFile = ./SKR_PICO_V1.0__firmware.env;
    };
    "STM32-Klipper-Expander" = {
      enable = true;
      enableKlipperFlash = true;
      serial = "/dev/null"; # can flash this mcu, but nixpkgs wants a path (we have USB id)

      # To flash:
      # 1. Boot pin jumper on mcu
      # 2. Get USB_ID from sudo dfu-util --list
      # 3. $ klipper-flash-STM32-Klipper-Expander
      # 4. Get klipper.bin from path given by step 3
      # 5. $ sudo dfu-util -d ,$USB_ID -R -a 0 -s 0x8000000:leave -D klipper.bin

      # To get this config file, run package 'klipper-genconf'
      # (make sure version match with pkgs.klipper)
      configFile = ./STM32-Klipper-Expander__firmware.env;
    };
  };
}
