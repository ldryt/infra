let
  dns = builtins.fromJSON (builtins.readFile ../../../dns.json);

  min-port = 10000;
  max-port = 20000;
  listening-port = 3478;
  tls-listening-port = 5349;
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

  services.coturn = {
    enable = true;
    realm = "${dns.subdomains.turn}.${dns.zone}";
    inherit min-port;
    inherit max-port;
    inherit listening-port;
    inherit tls-listening-port;
    lt-cred-mech = true;
    extraConfig = ''
      fingerprint
      user=test:test12308
      syslog
      verbose
    '';
  };
}
