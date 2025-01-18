{ pkgs, config, ... }:
let
  dns = builtins.fromJSON (builtins.readFile ../dns.json);
  internetInterface = "eth0";
  wireguardInterface = "domustunnel";
  wireguardPort = 62879;
  wgIp = "10.22.22";
  domusIp = "${wgIp}.22";
  domusPort = 8123;
in
{
  sops.secrets."system/wireguard/privateKey" = { };
  networking = {
    nat = {
      enable = true;
      externalInterface = internetInterface;
      internalInterfaces = [ wireguardInterface ];
    };
    firewall.allowedUDPPorts = [ wireguardPort ];
    wireguard.interfaces = {
      "${wireguardInterface}" = {
        ips = [ "${wgIp}.1/24" ];
        listenPort = wireguardPort;
        privateKeyFile = config.sops.secrets."system/wireguard/privateKey".path;
        postSetup = "${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s ${wgIp}.0/24 -o ${internetInterface} -j MASQUERADE";
        postShutdown = "${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s ${wgIp}.0/24 -o ${internetInterface} -j MASQUERADE";
        peers = [
          {
            # domus
            publicKey = "8rup20WbAXYpOxGXwUZwNtr49wR3viefWRsO8xSA2is=";
            allowedIPs = [ "${domusIp}/32" ];
          }
        ];
      };
    };
  };

  services.nginx.virtualHosts."${dns.subdomains.domus}.${dns.zone}" = {
    enableACME = true;
    forceSSL = true;
    kTLS = true;
    locations."/".proxyPass = "http://${domusIp}:${toString domusPort}";
  };
}
