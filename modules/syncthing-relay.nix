{ config, ... }:
{
  services.syncthing.relay = {
    enable = true;
    providedBy = "https://ldryt.dev";
  };
  networking.firewall.allowedTCPPorts = [
    config.services.syncthing.relay.statusPort
    config.services.syncthing.relay.port
  ];
}
