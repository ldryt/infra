{ ... }:
{
  imports = [
    ./nmprofiles.nix
    ../../../modules/dns.nix
  ];

  networking = {
    hostName = "tinkerbell";
    networkmanager = {
      enable = true;
      wifi = {
        backend = "iwd";
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
