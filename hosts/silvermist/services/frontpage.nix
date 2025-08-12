{ config, ... }:
{
  services.nginx.virtualHosts."${config.ldryt-infra.dns.zone}" = {
    enableACME = true;
    forceSSL = true;
    kTLS = true;
    locations."/".return = "302 https://github.com/ldryt";
  };
}
