{ ... }:
let
  dns = builtins.fromJSON (builtins.readFile ../dns.json);
in
{
  services.nginx.virtualHosts."${dns.zone}" = {
    enableACME = true;
    forceSSL = true;
    kTLS = true;
    locations."/".return = "302 https://github.com/ldryt";
  };
}
