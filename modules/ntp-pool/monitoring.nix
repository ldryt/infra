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

  ldryt-infra.monitoring = {
    endpoints.chrony = lib.mkIf monitoring.enable {
      port = config.services.prometheus.exporters.chrony.port;
    };

    jsonProbes = lib.mkIf (poolAddress != null) {
      ntppool = {
        scrapeInterval = "5m";
        target = "https://www.ntppool.org/scores/${poolAddress}/json?limit=1";
        metrics = [
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
      };

      ntppool-dns = {
        scrapeInterval = "5m";
        target = "https://www.ntppool.org/api/data/server/dns/answers/${poolAddress}";
        metrics = [
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
      };
    };
  };
}
