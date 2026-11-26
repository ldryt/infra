{ config, lib, ... }:
let
  monitoring = config.ldryt-infra.monitoring;
  metricsPort = 9999;
  ports = {
    from = 30000;
    to = 30511;
  };
in
{
  services.snowflake-proxy = {
    enable = true;
    capacity = lib.mkDefault 256;
    extraFlags = [ "-ephemeral-ports-range=${toString ports.from}:${toString ports.to}" ] ++ lib.optionals monitoring.enable [
      "-metrics"
      "-metrics-address=${monitoring.listenAddress}"
      "-metrics-port=${toString metricsPort}"
    ];
  };

  ldryt-infra.monitoring.endpoints.snowflake = lib.mkIf monitoring.enable {
    port = metricsPort;
    metricsPath = "/internal/metrics";
  };

  networking.firewall.allowedUDPPortRanges = [ ports ];

  systemd.services.snowflake-proxy.serviceConfig = {
    Restart = "on-failure";
    RestartSec = "5s";
  };
}
