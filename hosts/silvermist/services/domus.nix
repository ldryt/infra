{ config, ... }:
let
  dns = builtins.fromJSON (builtins.readFile ../dns.json);
  wireguardPort = 62879;
  wireguardIF = "domustunnel";
  wgIp = "10.22.22";
  domusIp = "${wgIp}.22";
  domusPort = 8123;
  domusPublicKey = "domucc9r8SkBuN3voZDs4KDj3TUQJiH08zQ2djO68g8=";
in
{
  sops.secrets."system/networking/wireguard/privateKey".owner = "systemd-network";
  networking.firewall.allowedUDPPorts = [ wireguardPort ];
  systemd.network = {
    enable = true;
    netdevs = {
      "10-${wireguardIF}" = {
        netdevConfig = {
          Kind = "wireguard";
          Name = wireguardIF;
        };
        wireguardConfig = {
          PrivateKeyFile = config.sops.secrets."system/networking/wireguard/privateKey".path;
          ListenPort = wireguardPort;
        };
        wireguardPeers = [
          {
            # domus
            PublicKey = domusPublicKey;
            AllowedIPs = [ domusIp ];
          }
        ];
      };
    };
    networks."${wireguardIF}" = {
      matchConfig.Name = wireguardIF;
      address = [ "${wgIp}.1/24" ];
      networkConfig = {
        IPMasquerade = "ipv4";
        IPv4Forwarding = true;
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
