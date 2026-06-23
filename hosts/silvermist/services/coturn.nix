{ lib, config, ... }:
let
  min-port = 10000;
  max-port = 20000;
  tls-listening-port = 5349;
  realm = config.ldryt-infra.dns.records.coturn;
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
      tls-listening-port
    ];
    allowedTCPPorts = [
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
      tls-listening-port
      ;

    lt-cred-mech = true;

    cert = "${config.security.acme.certs.${realm}.directory}/fullchain.pem";
    pkey = "${config.security.acme.certs.${realm}.directory}/key.pem";

    extraConfig = ''
      fingerprint
      syslog
      verbose
    '';
  };
  sops.secrets."services/coturn/users".owner = "turnserver";
  systemd.services.coturn.preStart = lib.mkAfter ''
    { echo ""; cat ${config.sops.secrets."services/coturn/users".path}; } >> /run/coturn/turnserver.cfg
  '';
}
