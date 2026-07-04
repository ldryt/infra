{ config, lib, ... }:
let
  common = import ./common.nix { };
  cfg = config.ldryt-infra.monitoring.base;
in
{
  options.ldryt-infra.monitoring.base = {
    enable = lib.mkEnableOption "monitoring config (node_exporter + fluent-bit)";

    listenAddress = lib.mkOption {
      type = lib.types.str;
      description = "IP address for node_exporter to listen on";
    };
  };

  options.ldryt-infra.monitoring.blackbox.targets = lib.mkOption {
    type = lib.types.attrsOf (lib.types.listOf lib.types.str);
    default = { };
  };

  config = lib.mkIf cfg.enable {
    services.fail2ban.ignoreIP = map (p: p.ip) (
      [ common.wg.server ] ++ builtins.attrValues common.wg.clients
    );

    services.prometheus.exporters.node = {
      enable = true;
      port = common.ports.nodeExporter;
      listenAddress = cfg.listenAddress;
      enabledCollectors = [
        "systemd"
      ];
    };

    services.fluent-bit = {
      enable = true;
      settings = {
        pipeline = {
          inputs = [
            {
              name = "systemd";
              tag = "journal";
            }
          ];
          outputs = [
            {
              name = "loki";
              match = "*";
              host = common.wg.server.ip;
              port = common.ports.loki;
              labels = "job=systemd-journal, host=${config.networking.hostName}, unit=$_SYSTEMD_UNIT, level=$PRIORITY";
            }
          ];
        };
      };
    };
  };
}
