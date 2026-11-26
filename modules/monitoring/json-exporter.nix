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
in
{
  options.ldryt-infra.monitoring.jsonExporter.modules = lib.mkOption {
    type = lib.types.attrsOf format.type;
    default = { };
    internal = true;
    description = "JSON exporter module configurations contributed by monitored services.";
  };

  config = lib.mkIf (monitoring.enable && monitoring.jsonExporter.modules != { }) {
    services.prometheus.exporters.json = {
      enable = true;
      port = common.ports.jsonExporter;
      listenAddress = monitoring.listenAddress;
      configFile = format.generate "prometheus-json-exporter.json" {
        inherit (monitoring.jsonExporter) modules;
      };
    };
  };
}
