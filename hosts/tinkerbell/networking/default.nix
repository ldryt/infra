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
        powersave = true;
        macAddress = "stable-ssid";
      };
      logLevel = "INFO";
    };
    firewall.allowedTCPPorts = [
      # Syncthing LAN
      22000
    ];
  };
}
