{ }:
{
  grafanaClientId = "2NADHAc~yxd~kNvfJg4PwJNXE1ErhAcQ2~9FPZEh2TgxLY_GIJdv1LluQGKv38iSy~JYNxo.";

  wg = {
    int = "wg-monitoring";
    subnet = "/24";
    port = 44821;
    server = {
      hostname = "domus";
      ip = "10.44.128.1";
      pubKey = "nuR6GcYBc1yejUQg0rVJXbsKl2+Y4GwjIwnMRzyavVs=";
    };

    clients = builtins.mapAttrs (hostname: v: v // { inherit hostname; }) {
      printer = {
        ip = "10.44.128.5";
        isEphemeral = true;
        pubKey = "oIj9Q5nKQ0BSCVzlbu6lAx97l9Kzu7Vltlp7jqVSGjc=";
      };
    };
  };

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
