{
  config,
  lib,
  pkgs,
  ...
}:
let
  common = import ./common.nix { };
  monitoring = config.ldryt-infra.monitoring;
  format = pkgs.formats.json { };
  probes = monitoring.jsonProbes;
in
{
  options.ldryt-infra.monitoring.jsonProbes = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          target = lib.mkOption { type = lib.types.str; };
          scrapeInterval = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
          metrics = lib.mkOption { type = lib.types.listOf format.type; };
        };
      }
    );
    default = { };
    internal = true;
    description = "JSON exporter probes keyed by Prometheus job name.";
  };

  config = lib.mkIf (monitoring.enable && probes != { }) {
    ldryt-infra.monitoring.endpoints = lib.mapAttrs (name: probe: {
      port = config.services.prometheus.exporters.json.port;
      metricsPath = "/probe";
      inherit (probe) scrapeInterval;
      params = {
        module = name;
        inherit (probe) target;
      };
    }) probes;

    services.prometheus.exporters.json = {
      enable = true;
      port = common.ports.jsonExporter;
      listenAddress = monitoring.listenAddress;
      configFile = format.generate "prometheus-json-exporter.json" {
        modules = lib.mapAttrs (_: probe: { inherit (probe) metrics; }) probes;
      };
    };
  };
}
