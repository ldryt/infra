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
        powersave = false;
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
  hardware.wirelessRegulatoryDatabase = true;
  boot.extraModprobeConfig = ''
    options mt7921e disable_aspm=1
    options cfg80211 ieee80211_regdom=FR
  '';
}
