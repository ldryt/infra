{ dns, ... }:
{
  services.nginx.virtualHosts."${dns.silvermist.zone}" = {
    enableACME = true;
    forceSSL = true;
    kTLS = true;
    locations."/".return = "302 https://github.com/ldryt";
  };
}
