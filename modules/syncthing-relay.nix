{ config, ... }:
{
  services.syncthing.relay = {
    enable = true;
    listenAddress = "0.0.0.0";
    statusListenAddress = "0.0.0.0";
    extraOptions = [
      "-protocol=tcp4"
      "-ext-address=${config.networking.hostName}.${config.ldryt-infra.dns.zone}:${builtins.toString config.services.syncthing.relay.port}"
    ];
    providedBy = "https://ldryt.dev";
  };
  networking.firewall.allowedTCPPorts = [
    config.services.syncthing.relay.statusPort
    config.services.syncthing.relay.port
  ];
}
