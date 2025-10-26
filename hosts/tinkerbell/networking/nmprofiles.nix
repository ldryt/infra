{ config, ... }:
{
  sops.secrets."system/NetworkManager/profiles/env" = { };
  networking.networkmanager.ensureProfiles = {
    environmentFiles = [ config.sops.secrets."system/NetworkManager/profiles/env".path ];
    profiles = rec {
      wg_GNB = {
        connection = {
          id = "wg_GNB";
          interface-name = "wg_GNB";
          type = "wireguard";
        };
        ipv4 = {
          address1 = "192.168.27.65/32";
          method = "manual";
        };
        ipv6 = {
          method = "disabled";
        };
        wireguard = {
          mtu = "1360";
          private-key = "$wg_GNB_PRIVATE_KEY";
        };
        "wireguard-peer.auwq1FbYBSiMBTktf105iLyIv6CRPIK5KGy9zvdVNhE=" = {
          allowed-ips = "0.0.0.0/0;192.168.27.64/27;192.168.0.0/24;";
          endpoint = "$wg_GNB_ENDPOINT";
          preshared-key = "$wg_GNB_PRESHARED_KEY";
          preshared-key-flags = "0";
        };
      };
      LYS = {
        connection = {
          id = "$LYS_SSID";
          type = "wifi";
        };
        ipv4 = {
          method = "auto";
          dhcp-send-hostname = false;
        };
        ipv6 = {
          method = "auto";
          ip6-privacy = "2";
          dhcp-duid = "stable-uuid";
          dhcp-send-hostname = false;
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
      VNO = {
        connection = {
          id = "$VNO_SSID";
          type = "wifi";
        };
        wifi = {
          mode = "infrastructure";
          ssid = "$VNO_SSID";
        };
        wifi-security = {
          key-mgmt = "wpa-psk";
          psk = "$VNO_PWD";
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
      tp420ia = {
        connection = {
          id = "tp420ia";
          type = "wifi";
        };
        wifi = {
          mode = "infrastructure";
          ssid = "tp420ia";
        };
        wifi-security = {
          key-mgmt = "wpa-psk";
          psk = "$TP420IA_PWD";
        };
      };
      Eduroam = {
        "802-1x" = {
          eap = "peap;";
          identity = "$eduroam_ID";
          password = "$eduroam_PWD";
          phase2-auth = "mschapv2";
        };
        connection = {
          id = "Eduroam";
          type = "wifi";
        };
        wifi = {
          mode = "infrastructure";
          ssid = "Eduroam";
        };
        wifi-security = {
          auth-alg = "open";
          key-mgmt = "wpa-eap";
        };
      };
      IONIS = {
        "802-1x" = {
          eap = "peap;";
          identity = "$eduroam_ID";
          password = "$eduroam_PWD";
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
      eduroam = {
        "802-1x" = {
          eap = "peap;";
          identity = "$eduroam_ID";
          password = "$eduroam_PWD";
          phase2-auth = "mschapv2";
        };
        connection = {
          id = "eduroam";
          type = "wifi";
        };
        wifi = {
          mode = "infrastructure";
          ssid = "eduroam";
        };
        wifi-security = {
          auth-alg = "open";
          key-mgmt = "wpa-eap";
        };
      };
    };
  };
}
