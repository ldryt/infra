{
  config,
  lib,
  ...
}:
let
  common = import ../monitoring/common.nix { };
  monitoring = config.ldryt-infra.monitoring;
  publicIPs = builtins.fromJSON (builtins.readFile ../../ips.json);
  poolAddress = publicIPs.${config.networking.hostName} or null;
in
{
  services.prometheus.exporters.chrony = lib.mkIf monitoring.enable {
    enable = true;
    port = common.ports.chronyExporter;
    listenAddress = monitoring.listenAddress;
    enabledCollectors = [
      "tracking"
      "sources"
      "serverstats"
    ];
    disabledCollectors = [
      "sources.with-ntpdata"
      "dns-lookups"
    ];
  };

  ldryt-infra.monitoring = lib.mkMerge [
    (lib.mkIf monitoring.enable {
      endpoints.chrony.port = config.services.prometheus.exporters.chrony.port;
    })
    (lib.mkIf (monitoring.enable && poolAddress != null) {
      endpoints.ntppool = {
        port = config.services.prometheus.exporters.json.port;
        metricsPath = "/probe";
        scrapeInterval = "5m";
        params = {
          module = "ntppool";
          target = "https://www.ntppool.org/scores/${poolAddress}/json?limit=1";
        };
      };

      jsonExporter.modules.ntppool.metrics = [
        {
          name = "ntppool_score";
          path = "{.history[0].score}";
          help = "Latest aggregate NTP Pool score.";
          valuetype = "gauge";
        }
        {
          name = "ntppool_score_timestamp_seconds";
          path = "{.history[0].ts}";
          help = "Unix timestamp of the latest aggregate NTP Pool score, in seconds.";
          valuetype = "gauge";
        }
      ];

      endpoints.ntppool-dns = {
        port = config.services.prometheus.exporters.json.port;
        metricsPath = "/probe";
        scrapeInterval = "5m";
        params = {
          module = "ntppool-dns";
          target = "https://www.ntppool.org/api/data/server/dns/answers/${poolAddress}";
        };
      };

      jsonExporter.modules.ntppool-dns.metrics = [
        {
          name = "ntppool_dns";
          type = "object";
          path = "{.Server[*]}";
          help = "NTP Pool DNS answer share in parts per ten thousand.";
          labels.country = "{.CC}";
          values.answer_points = "{.Points}";
          values.expected_points = "{.Netspeed}";
          valuetype = "gauge";
        }
        {
          name = "ntppool_dns";
          type = "object";
          path = "{.Server[*]}";
          help = "NTP Pool DNS answer count by client country.";
          labels.country = "{.CC}";
          values.answers = "{.Count}";
          valuetype = "gauge";
        }
      ];
    })
  ];

}
