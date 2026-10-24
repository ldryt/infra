{ }:
rec {
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
        pubKey = "oIj9Q5nKQ0BSCVzlbu6lAx97l9Kzu7Vltlp7jqVSGjc=";
        isEphemeral = true;
      };
    };
  };

  ports = {
    loki = 44142;
    lokiGrpc = 44192;
    prometheus = 44141;
    nodeExporter = 44191;
    wireguardExporter = 44194;
    blackbox = 44190;
    grafana = 44144;
    alertmanager = 44193;
  };
}
