{ config, ... }:
{
  sops.secrets."system/NetworkManager/profiles/env" = { };
  networking.networkmanager.ensureProfiles = {
    environmentFiles = [ config.sops.secrets."system/NetworkManager/profiles/env".path ];
    profiles = {
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
    };
  };
}
