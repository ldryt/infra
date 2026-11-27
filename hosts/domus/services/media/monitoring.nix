{ mediaAdminApps }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  monitoring = config.ldryt-infra.monitoring;
  arrApps = builtins.removeAttrs mediaAdminApps [ "qbittorrent" ];
  qbittorrentApi = mediaAdminApps.qbittorrent;
  inherit (config.nixarr) stateDir;

  jellyfinExporter = pkgs.fetchzip rec {
    # renovate: datasource=github-releases depName=rebelcore/jellyfin_exporter
    version = "1.6.0";
    url = "https://github.com/rebelcore/jellyfin_exporter/releases/download/v${version}/jellyfin_exporter-${version}.linux-amd64.tar.gz";
    hash = "sha256-Tyznpk5qiqLhRp0EbYcv2hqcyaRjsYunfoUeY338XHQ=";
  };
  jellyfinExporterPort = 9594;
  jellyfinExporterKey = "services/monitoring/endpoints/jellyfin/apiKey";
in
{
  config = lib.mkMerge [
    {
      sops.secrets.${jellyfinExporterKey}.restartUnits = [ "jellyfin-exporter.service" ];
    }
    (lib.mkIf monitoring.enable {
      systemd.services =
        lib.mapAttrs' (
          name: _:
          lib.nameValuePair "prometheus-exportarr-${name}-exporter" {
            after = [ "${name}-api.service" ];
            requires = [ "${name}-api.service" ];
          }
        ) arrApps
        // {
          jellyfin-exporter = {
            description = "Jellyfin Prometheus exporter";
            wantedBy = [ "multi-user.target" ];
            after = [ "jellyfin.service" ];
            serviceConfig = {
              DynamicUser = true;
              LoadCredential = "api-key:${config.sops.secrets.${jellyfinExporterKey}.path}";
              Restart = "on-failure";
            };
            script = ''
              export JELLYFIN_TOKEN="$(<"$CREDENTIALS_DIRECTORY/api-key")"
              exec ${jellyfinExporter}/jellyfin_exporter \
                --web.listen-address=127.0.0.1:${toString jellyfinExporterPort} \
                --collector.disable-defaults --collector.playing --collector.transcoding
            '';
          };
        };

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

      services.prometheus.scrapeConfigs = lib.mkAfter [
        {
          job_name = "jellyfin";
          static_configs = [
            {
              targets = [ "127.0.0.1:${toString jellyfinExporterPort}" ];
              labels.instance = config.networking.hostName;
            }
          ];
          metric_relabel_configs = [
            {
              source_labels = [ "__name__" ];
              regex = "jellyfin_(now_playing_state|transcoding_sessions)";
              action = "keep";
            }
            {
              regex = "__name__|instance|job|session_id";
              action = "labelkeep";
            }
          ];
        }
      ];
    })
  ];
}
