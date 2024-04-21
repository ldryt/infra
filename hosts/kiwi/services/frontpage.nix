{ vars, ... }:
{
  services.nginx.virtualHosts."${vars.zone}" = {
    enableACME = true;
    forceSSL = true;
    kTLS = true;
    locations."/".return = "302 https://github.com/ldryt";
  };
}
