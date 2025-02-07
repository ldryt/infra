{ config, ... }:
{
  imports = [
    ../../modules/sd-image-aarch64.nix

    ./networking.nix
    ./users.nix

    ../../modules/openssh.nix
    ../../modules/nix-settings.nix
  ];

  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.keyFile = "/nix/sops_age_printer.key";
  };

  system.stateVersion = "23.05";

  services.klipper = {
    enable = true;
    user = config.services.moonraker.user;
    group = config.services.moonraker.group;
    configFile = ./VORON0.2_SKR_PICO_V1.0.ini;
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
          "http://${config.services.avahi.hostName}.${config.services.avahi.domainName}"
          "https://printer.ldryt.dev"
        ];
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 ];
  services.mainsail.enable = true;
}
