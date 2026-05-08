{ config, lib, ... }:
let
  common = import ./common.nix { };
  cfg = config.ldryt-infra.monitoring.client;
in
{
  imports = [ ./base.nix ];

  options.ldryt-infra.monitoring.client = {
    enable = lib.mkEnableOption "monitoring client";
    wg = {
      privateKeyFile = lib.mkOption {
        type = lib.types.path;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    ldryt-infra.monitoring.base = {
      enable = true;
      listenAddress = common.wg.clients.${config.networking.hostName}.ip;
    };

    networking.firewall.allowedUDPPorts = [ common.wg.port ];
    networking.wireguard.interfaces."${common.wg.int}" = {
      ips = [ "${common.wg.clients.${config.networking.hostName}.ip}${common.wg.subnet}" ];
      privateKeyFile = cfg.wg.privateKeyFile;
      peers = [
        {
          publicKey = common.wg.server.pubKey;
          allowedIPs = [ "${common.wg.server.ip}/32" ];
          endpoint = "${common.wg.server.hostname}.${config.ldryt-infra.dns.zone}:${toString common.wg.port}";
          persistentKeepalive = 25;
        }
      ];
    };
    networking.firewall.interfaces."${common.wg.int}".allowedTCPPorts = [ common.ports.nodeExporter ];
  };
}
