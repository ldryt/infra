{ config, lib, ... }:
let
  common = import ./common.nix { };
  cfg = config.ldryt-infra.monitoring;
  hostname = config.networking.hostName;
  peer =
    if hostname == common.wg.server.hostname then
      common.wg.server
    else
      common.wg.clients.${hostname}
        or (throw "Add ${hostname} to the monitoring WireGuard inventory before enabling monitoring.");
in
{
  options.ldryt-infra.monitoring = {
    enable = lib.mkEnableOption "monitoring metrics and journal forwarding";

    listenAddress = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      description = "Host address on the monitoring WireGuard network.";
    };
  };

  options.ldryt-infra.monitoring.endpoints = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          port = lib.mkOption {
            type = lib.types.port;
            description = "TCP port serving Prometheus metrics on the monitoring address.";
          };
          metricsPath = lib.mkOption {
            type = lib.types.str;
            default = "/metrics";
            description = "HTTP path to scrape on this endpoint.";
          };
          params = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            default = { };
            description = "HTTP query parameters to send when scraping this endpoint.";
          };
          scrapeInterval = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Prometheus scrape interval for this job, shared by all hosts registering the job.";
          };
        };
      }
    );
    default = { };
    description = "Prometheus metrics endpoints to scrape over WireGuard, keyed by job name.";
  };

  options.ldryt-infra.monitoring.blackbox.targets = lib.mkOption {
    type = lib.types.attrsOf (lib.types.listOf lib.types.str);
    default = { };
    description = "Targets for the central Blackbox Exporter, keyed by probe module.";
  };

  config = lib.mkIf cfg.enable {
    ldryt-infra.monitoring.listenAddress = peer.ip;

    systemd.services.monitoring-wireguard-online = lib.mkIf config.networking.wireguard.useNetworkd {
      before = [
        "alertmanager.service"
        "crowdsec.service"
      ];
      requiredBy = lib.optional config.services.prometheus.alertmanager.enable "alertmanager.service";
      wantedBy = lib.optional config.services.crowdsec.enable "crowdsec.service";
      after = [ "systemd-networkd.service" ];
      requires = [ "systemd-networkd.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${config.systemd.package}/lib/systemd/systemd-networkd-wait-online --interface=${common.wg.int}:degraded --ipv4 --timeout=60";
      };
    };

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

    ldryt-infra.monitoring.endpoints.nodes.port = config.services.prometheus.exporters.node.port;

    networking.firewall.interfaces.${common.wg.int}.allowedTCPPorts = map (endpoint: endpoint.port) (
      builtins.attrValues config.ldryt-infra.monitoring.endpoints
    );

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
          filters = [
            {
              name = "modify";
              match = "journal";
              condition = "Key_value_matches _SYSTEMD_UNIT [.]service$";
              copy = "_SYSTEMD_UNIT monitoring_unit";
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
              labels = "job=systemd-journal, host=${hostname}, unit=$monitoring_unit";
            }
          ];
        };
      };
    };
  };
}
