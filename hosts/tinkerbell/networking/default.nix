{ ... }:
{
  imports = [
    ./nmprofiles.nix
    ../../../modules/dnscrypt-proxy.nix
  ];

  networking = {
    hostName = "tinkerbell";
    networkmanager = {
      enable = true;
      wifi = {
        powersave = true;
        macAddress = "stable-ssid";
      };
      logLevel = "INFO";
    };
    firewall = {
      allowedTCPPorts = [
        # Syncthing LAN
        22000
      ];
      # Don't drop wireguard packets
      checkReversePath = "loose";
    };
  };
}
