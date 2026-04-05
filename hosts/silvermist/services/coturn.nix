{ config, ... }:
let
  min-port = 10000;
  max-port = 20000;
  listening-port = 3478;
  tls-listening-port = 5349;
  realm = config.ldryt-infra.dns.records.turn;
in
{
  networking.firewall = {
    allowedUDPPortRanges = [
      {
        from = min-port;
        to = max-port;
      }
    ];
    allowedUDPPorts = [
      listening-port
      tls-listening-port
    ];
    allowedTCPPorts = [
      listening-port
      tls-listening-port
    ];
  };

  sops.secrets."services/coturn/certs/acme/env" = { };
  security.acme.certs."${realm}" = {
    dnsProvider = "desec";
    environmentFile = config.sops.secrets."services/coturn/certs/acme/env".path;
    group = "turnserver";
  };

  services.coturn = {
    enable = true;
    inherit
      realm
      min-port
      max-port
      listening-port
      tls-listening-port
      ;

    lt-cred-mech = true;

    cert = "${config.security.acme.certs.${realm}.directory}/fullchain.pem";
    pkey = "${config.security.acme.certs.${realm}.directory}/key.pem";

    extraConfig = ''
      fingerprint
      user=test:test12308
      syslog
      verbose
    '';
  };
}
