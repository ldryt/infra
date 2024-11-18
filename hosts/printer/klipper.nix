{ config, ... }:
{
  services.klipper = {
    enable = true;
    configFile = ./VORON0.2_SKR_PICO_V1.0.ini;
  };

  security.polkit.enable = true;
  services.moonraker = {
    enable = true;
    allowSystemControl = true;
    settings = {
      authorization = {
        trusted_clients = [
          "::1"
          "127.0.0.1"
        ];
        #cors_domains = [ "http://${config.services.avahi.hostName}.${config.services.avahi.domainName}" ];
      };
    };
  };

  services.mainsail.enable = true;
}
