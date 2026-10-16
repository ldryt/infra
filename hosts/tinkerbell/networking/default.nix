{ ... }:
{
  imports = [
    ./nmprofiles.nix
    ../../../modules/nextdns.nix
  ];

  ldryt-infra.persist.files = [
    "/var/lib/NetworkManager/secret_key"
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
      settings.connectivity = {
        enable = true;
        uri = "http://nmcheck.gnome.org/check_network_status.txt";
        response = "NetworkManager is online";
      };
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
  services.avahi = {
    enable = true;
    nssmdns4 = true;
  };
  hardware.wirelessRegulatoryDatabase = true;
  boot.extraModprobeConfig = ''
    options mt7921e disable_aspm=1
    options cfg80211 ieee80211_regdom=FR
  '';
}
