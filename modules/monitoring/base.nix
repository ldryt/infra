{ config, lib, ... }:
let
  common = import ./common.nix { };
  cfg = config.ldryt-infra.monitoring.base;
in
{
  options.ldryt-infra.monitoring.base = {
    enable = lib.mkEnableOption "monitoring config (node_exporter + promtail)";

    listenAddress = lib.mkOption {
      type = lib.types.str;
      description = "IP address for node_exporter to listen on";
    };
  };

  config = lib.mkIf cfg.enable {
    services.prometheus.exporters.node = {
      enable = true;
      port = common.ports.nodeExporter;
      listenAddress = cfg.listenAddress;
      enabledCollectors = [
        "systemd"
      ];
    };

    services.promtail = {
      enable = true;
      configuration = {
        server.http_listen_port = common.ports.promtail;
        clients = [
          { url = "http://${common.wg.server.ip}:${toString common.ports.loki}/loki/api/v1/push"; }
        ];
        scrape_configs = [
          {
            job_name = "journal";
            journal = {
              max_age = "12h";
              labels = {
                job = "systemd-journal";
                host = config.networking.hostName;
              };
            };
            relabel_configs = [
              {
                source_labels = [ "__journal__systemd_unit" ];
                target_label = "unit";
              }
              {
                source_labels = [ "__journal__priority" ];
                target_label = "level";
              }
            ];
          }
        ];
      };
    };
  };
}
