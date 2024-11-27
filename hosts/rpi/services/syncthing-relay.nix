{ config, ... }:
{
  networking.firewall.allowedTCPPorts = [
    config.services.syncthing.relay.port
    config.services.syncthing.relay.statusPort
  ];

  services.syncthing.relay = {
    enable = true;
    providedBy = "ldryt.dev";
    listenAddress = "0.0.0.0";
    statusListenAddress = "0.0.0.0";
  };
}
