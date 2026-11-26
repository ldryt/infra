{ config, lib, ... }:
let
  relay = config.services.syncthing.relay;
  monitoring = config.ldryt-infra.monitoring;
in
{
  ldryt-infra.monitoring = lib.mkIf monitoring.enable {
    endpoints.strelay = {
      port = config.services.prometheus.exporters.json.port;
      metricsPath = "/probe";
      params = {
        module = "strelay";
        target = "http://127.0.0.1:${toString relay.statusPort}/status";
      };
    };

    jsonExporter.modules.strelay.metrics = [
      {
        name = "strelay_bytes_proxied_total";
        path = "{.bytesProxied}";
        help = "Total bytes proxied by the relay.";
        valuetype = "counter";
      }
      {
        name = "strelay_active_sessions";
        path = "{.numActiveSessions}";
        help = "Active relay sessions.";
        valuetype = "gauge";
      }
      {
        name = "strelay_connections";
        path = "{.numConnections}";
        help = "Active relay connections.";
        valuetype = "gauge";
      }
      {
        name = "strelay_pending_session_keys";
        path = "{.numPendingSessionKeys}";
        help = "Pending relay session keys.";
        valuetype = "gauge";
      }
      {
        name = "strelay_proxies";
        path = "{.numProxies}";
        help = "Active unidirectional relay proxies.";
        valuetype = "gauge";
      }
      {
        name = "strelay_uptime_seconds";
        path = "{.uptimeSeconds}";
        help = "Time since the relay started, in seconds.";
        valuetype = "gauge";
      }
    ];
  };
}
