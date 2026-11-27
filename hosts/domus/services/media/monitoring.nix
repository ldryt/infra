{ mediaAdminApps }:
{ config, lib, ... }:
let
  monitoring = config.ldryt-infra.monitoring;
  arrApps = builtins.removeAttrs mediaAdminApps [ "qbittorrent" ];
  qbittorrentApi = mediaAdminApps.qbittorrent;
  inherit (config.nixarr) stateDir;
in
{
  config = lib.mkIf monitoring.enable {
    systemd.services = lib.mapAttrs' (
      name: _:
      lib.nameValuePair "prometheus-exportarr-${name}-exporter" {
        after = [ "${name}-api.service" ];
        requires = [ "${name}-api.service" ];
      }
    ) arrApps;

    services.prometheus.exporters = lib.mapAttrs' (
      name: app:
      lib.nameValuePair "exportarr-${name}" {
        enable = true;
        port = config.nixarr.${name}.exporter.port;
        inherit (monitoring) listenAddress;
        environment.INTERFACE = monitoring.listenAddress;
        url = "http://${app.host}:${toString app.port}";
        apiKeyFile = "${stateDir}/secrets/${name}.api-key";
      }
    ) arrApps;

    ldryt-infra.monitoring = {
      endpoints = lib.mapAttrs (name: _: {
        port = config.services.prometheus.exporters."exportarr-${name}".port;
      }) arrApps;

      jsonProbes.qbittorrent = {
        target = "http://${qbittorrentApi.host}:${toString qbittorrentApi.port}/api/v2/transfer/info";
        metrics = [
          {
            name = "qbittorrent_download_bytes_per_second";
            path = "{.dl_info_speed}";
            help = "Total qBittorrent download rate in bytes per second.";
            valuetype = "gauge";
          }
          {
            name = "qbittorrent_upload_bytes_per_second";
            path = "{.up_info_speed}";
            help = "Total qBittorrent upload rate in bytes per second.";
            valuetype = "gauge";
          }
        ];
      };
    };
  };
}
