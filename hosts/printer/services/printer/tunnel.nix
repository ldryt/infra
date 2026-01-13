{ config, ... }:
let
  wireguardIF = "printertunnel";
  wgIp = "10.22.22";
  selfWgIp = "${wgIp}.22";
  silvermistIp = "${wgIp}.1";
  silvermistEndpoint = "printer.ldryt.dev:62879";
  silvermistPublicKey = "silv6SFoJoB7njsaIRTi55CaTb1RkRcM6pVx/WE5m38=";
in
{
  sops.secrets."system/networking/wireguard/privateKey".owner = "systemd-network";
  systemd.network = {
    netdevs."10-${wireguardIF}" = {
      netdevConfig = {
        Kind = "wireguard";
        Name = "${wireguardIF}";
      };
      wireguardConfig = {
        PrivateKeyFile = config.sops.secrets."system/networking/wireguard/privateKey".path;
        ListenPort = 61495;
      };
      wireguardPeers = [
        {
          # silvermist
          PublicKey = silvermistPublicKey;
          AllowedIPs = [ silvermistIp ];
          Endpoint = silvermistEndpoint;
          PersistentKeepalive = 25;
        }
      ];
    };
    networks."10-${wireguardIF}" = {
      matchConfig.Name = wireguardIF;
      address = [ "${selfWgIp}/24" ];
    };
  };

}
