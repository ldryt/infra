{ }:
rec {
  wg = {
    int = "wg-monitoring";
    subnet = "/24";
    port = 44821;
    server = {
      hostname = "silvermist";
      ip = "10.44.128.1";
      pubKey = "N2D8K/2DZE7DwZlDhJdKw+kgyocQMJT5kr9IJ+wpdFA=";
    };

    clients = builtins.mapAttrs (hostname: v: v // { inherit hostname; }) {
      domus = {
        ip = "10.44.128.2";
        pubKey = "nuR6GcYBc1yejUQg0rVJXbsKl2+Y4GwjIwnMRzyavVs=";
        isEphemeral = true;
      };
      luke = {
        ip = "10.44.128.3";
        pubKey = "mpUwzziqZqgtgdrWxlkqISi+LLssmmnP+gHoBRVRhm0=";
        isEphemeral = false;
      };
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
    blackbox = 44190;
    grafana = 44144;
    alertmanager = 44193;
  };
}
