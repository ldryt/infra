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

    services.prometheus.exporters.wireguard = {
      enable = true;
      port = common.ports.wireguardExporter;
      listenAddress = cfg.listenAddress;
      interfaces = [ ]; # every interfaces
    };

    networking.firewall.interfaces."${common.wg.int}".allowedTCPPorts = [
      common.ports.wireguardExporter
    ];

    ldryt-infra.persist.directories = [
      {
        directory = "/var/lib/private/fluent-bit";
        mode = "0700";
      }
    ];
    systemd.services.fluent-bit.serviceConfig.StateDirectory = "fluent-bit";

    services.fluent-bit = {
      enable = true;
      settings = {
        service."storage.path" = "/var/lib/fluent-bit/buffer";
        pipeline = {
          inputs = [
            {
              name = "systemd";
              tag = "journal";
              read_from_tail = "on";
              db = "/var/lib/fluent-bit/journal.db";
              "storage.type" = "filesystem";
            }
          ];
          outputs = [
            {
              name = "loki";
              match = "*";
              host = common.wg.server.ip;
              port = common.ports.loki;
              retry_limit = "no_limits";
              "storage.total_limit_size" = "256M";
              labels = "job=systemd-journal, host=${config.networking.hostName}";
            }
          ];
        };
      };
    };
  };
}
