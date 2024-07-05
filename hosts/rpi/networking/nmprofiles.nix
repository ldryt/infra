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
          uuid = "f735668e-a38a-4c47-a072-1445aa7c44ce";
        };
        ipv4 = {
          method = "auto";
        };
        ipv6 = {
          addr-gen-mode = "default";
          method = "auto";
        };
        wifi = {
          mode = "infrastructure";
          ssid = "$GNB_SSID";
        };
        wifi-security = {
          auth-alg = "open";
          key-mgmt = "wpa-psk";
          psk = "$GNB_PWD";
        };
      };
      rosetta = {
        connection = {
          id = "rosetta";
          type = "wifi";
          uuid = "1517904d-776e-4633-ac49-a808c5d3215e";
        };
        wifi = {
          mode = "infrastructure";
          ssid = "rosetta";
        };
        wifi-security = {
          auth-alg = "open";
          key-mgmt = "wpa-psk";
          psk = "$ROSETTA_PWD";
        };
      };
    };
  };
}
