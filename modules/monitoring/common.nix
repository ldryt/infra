{ }:
{
  grafanaClientId = "2NADHAc~yxd~kNvfJg4PwJNXE1ErhAcQ2~9FPZEh2TgxLY_GIJdv1LluQGKv38iSy~JYNxo.";

  ports = {
    loki = 44142;
    lokiGrpc = 44192;
    prometheus = 44141;
    nodeExporter = 44191;
    chronyExporter = 44195;
    jsonExporter = 44196;
    blackbox = 44190;
    grafana = 44144;
    alertmanager = 44193;
  };
}
