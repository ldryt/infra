{ config, ... }:
{
  imports = [ ../../modules/dns.nix ];

  sops.secrets."nmprofiles.env" = { };
  networking = {
    hostName = "printer";
    networkmanager = {
      enable = true;
      wifi.powersave = false;
      logLevel = "INFO";
      ensureProfiles = {
        environmentFiles = [ config.sops.secrets."nmprofiles.env".path ];
        profiles = {
          GNB = {
            connection = {
              id = "$GNB_SSID";
              type = "wifi";
              autoconnect-priority = 10;
            };
            wifi.ssid = "$GNB_SSID";
            wifi-security = {
              key-mgmt = "wpa-psk";
              psk = "$GNB_PWD";
            };
          };
          ROS = {
            connection = {
              id = "$ROS_SSID";
              type = "wifi";
              autoconnect-priority = -10;
            };
            wifi.ssid = "$ROS_SSID";
            wifi-security = {
              key-mgmt = "wpa-psk";
              psk = "$ROS_PWD";
            };
          };
        };
      };
    };
  };

  services.avahi = {
    enable = true;
    ipv6 = true;
    nssmdns6 = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
    };
  };
}
