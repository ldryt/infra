{ config, ... }:
{
  sops.secrets."system/NetworkManager/profiles/env" = { };
  networking.networkmanager.ensureProfiles = {
    environmentFiles = [ config.sops.secrets."system/NetworkManager/profiles/env".path ];
    profiles = {
      LYS = {
        connection = {
          id = "$LYS_SSID";
          type = "wifi";
        };
        wifi = {
          mode = "infrastructure";
          ssid = "$LYS_SSID";
        };
        wifi-security = {
          key-mgmt = "wpa-psk";
          psk = "$LYS_PWD";
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
      };
      IONIS = {
        "802-1x" = {
          eap = "peap;";
          identity = "$IONIS_ID";
          password = "$IONIS_PWD";
          phase2-auth = "mschapv2";
        };
        connection = {
          id = "IONIS";
          type = "wifi";
        };
        wifi = {
          mode = "infrastructure";
          ssid = "IONIS";
        };
        wifi-security = {
          auth-alg = "open";
          key-mgmt = "wpa-eap";
        };
      };
    };
  };
}
