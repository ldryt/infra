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
          "10.0.0.0/8"
          "127.0.0.0/8"
          "169.254.0.0/16"
          "172.16.0.0/12"
          "192.168.0.0/16"
          "FE80::/10"
          "::1/128"
        ];
        cors_domains = [ "http://${config.services.avahi.hostName}.${config.services.avahi.domainName}" ];
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 ];
  services.mainsail.enable = true;
}
