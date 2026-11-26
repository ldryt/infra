{ config, lib, ... }:
let
  common = import ./common.nix { };
  cfg = config.ldryt-infra.monitoring;
in
{
  imports = [
    ./base.nix
    ./json-exporter.nix
  ];

  options.ldryt-infra.monitoring.isServer = lib.mkOption {
    type = lib.types.bool;
    default = false;
    internal = true;
  };

  options.ldryt-infra.monitoring.client.wg.privateKeyFile = lib.mkOption {
    type = lib.types.path;
  };

  config = lib.mkIf (cfg.enable && !cfg.isServer) {
    networking.firewall.allowedUDPPorts = [ common.wg.port ];
    networking.wireguard.interfaces."${common.wg.int}" = {
      ips = [ "${cfg.listenAddress}${common.wg.subnet}" ];
      privateKeyFile = cfg.client.wg.privateKeyFile;
      peers = [
        {
          publicKey = common.wg.server.pubKey;
          allowedIPs = [ "${common.wg.server.ip}/32" ];
          endpoint = "${common.wg.server.hostname}.${config.ldryt-infra.dns.zone}:${toString common.wg.port}";
          persistentKeepalive = 25;
        }
      ];
    };
  };
}
