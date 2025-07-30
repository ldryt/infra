{ config, ... }:
{
  sops.secrets."system/NetworkManager/profiles/env" = { };
  networking.networkmanager.ensureProfiles = {
    environmentFiles = [ config.sops.secrets."system/NetworkManager/profiles/env".path ];
    profiles = {
      enp3s0f4u1i4 = {
        connection = {
          id = "enp3s0f4u1i4";
          interface-name = "enp3s0f4u1i4";
          type = "802-3-ethernet";
        };
        ipv4 = {
          method = "auto";
          route-metric = 200;
        };
        ipv6 = {
          method = "disabled";
        };
      };
      enp3s0f3u1u2 = {
        connection = {
          id = "enp3s0f3u1u2";
          type = "802-3-ethernet";
          interface-name = "enp3s0f3u1u2";
          autoconnect = "no";
        };
      };
      GNB = {
        connection = {
          id = "$GNB_SSID";
          type = "wifi";
        };
        wifi = {
          mode = "infrastructure";
          ssid = "$GNB_SSID";
        };
        wifi-security = {
          key-mgmt = "wpa-psk";
          psk = "$GNB_PWD";
        };
        ipv4 = {
          method = "auto";
          route-metric = 20;
        };
        ipv6 = {
          method = "disabled";
        };
      };
      rosetta = {
        connection = {
          id = "rosetta";
          type = "wifi";
        };
        wifi = {
          mode = "infrastructure";
          ssid = "rosetta";
        };
        wifi-security = {
          key-mgmt = "wpa-psk";
          psk = "$ROSETTA_PWD";
        };
        ipv4 = {
          method = "auto";
          route-metric = 10;
        };
        ipv6 = {
          method = "disabled";
        };
      };
    };
  };
}
