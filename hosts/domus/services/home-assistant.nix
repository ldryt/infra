{ config, ... }:
let
  wireguardIF = "domustunnel";
  wgIp = "10.22.22";
  selfWgIp = "${wgIp}.22";
  silvermistIp = "${wgIp}.1";
  silvermistEndpoint = "domus.ldryt.dev:62879";
  silvermistPublicKey = "silv6SFoJoB7njsaIRTi55CaTb1RkRcM6pVx/WE5m38=";
  backupsDir = "/mnt/home-assistant";
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
          PersistentKeepalive = 2;
        }
      ];
    };
    networks."10-${wireguardIF}" = {
      matchConfig.Name = wireguardIF;
      address = [ "${selfWgIp}/24" ];
    };
  };

  users.users.colon.extraGroups = [ "dialout" ];
  virtualisation.oci-containers = {
    backend = "podman";
    containers.home-assistant = {
      image = "ghcr.io/home-assistant/home-assistant:2025.3.3";
      environment.TZ = "Europe/Paris";
      volumes = [
        "home-assistant:/config"
        "${backupsDir}:/config/backups"
      ];
      ports = [ "0.0.0.0:8123:8123" ];
      extraOptions = [
        "--device=/dev/serial/by-id/usb-1a86_USB_Serial-if00-port0:/dev/serial/by-id/usb-1a86_USB_Serial-if00-port0"
      ];
    };
  };
  systemd.services."podman-home-assistant".serviceConfig.RestartSec = "15s";

  ldryt-infra.backups.home-assistant = {
    paths = [ backupsDir ];
  };
}
