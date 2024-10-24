{ config, ... }:
{
  sops.secrets."system/NetworkManager/profiles/env" = { };
  sops.secrets."system/NetworkManager/profiles/mullvad_fr_par/ca" = { };
  networking.networkmanager.ensureProfiles = {
    environmentFiles = [ config.sops.secrets."system/NetworkManager/profiles/env".path ];
    profiles = {
      LYS = {
        connection = {
          id = "$LYS_SSID";
          type = "wifi";
          uuid = "8ce486c4-3f49-4a0d-8049-29006d1cfb7f";
        };
        ipv4 = {
          method = "auto";
          dhcp-send-hostname = "false";
          ignore-auto-dns = "true";
        };
        ipv6 = {
          method = "auto";
          dhcp-send-hostname = "false";
          ignore-auto-dns = "true";
        };
        wifi = {
          cloned-mac-address = "random";
          mode = "infrastructure";
          band = "bg";
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
      mullvad_fr_par = {
        connection = {
          autoconnect = "false";
          id = "Mullvad Paris";
          type = "vpn";
          uuid = "8f02cd11-8df7-440d-bbe0-efa27cad96fd";
        };
        vpn = {
          ca = config.sops.secrets."system/NetworkManager/profiles/mullvad_fr_par/ca".path;
          challenge-response-flags = "2";
          cipher = "AES-256-GCM";
          connection-type = "password";
          dev = "tun";
          password-flags = "0";
          ping = "10";
          ping-restart = "60";
          remote = "193.32.126.82:1301, 146.70.184.194:1301, 193.32.126.83:1301, 146.70.184.130:1301, 193.32.126.81:1301";
          remote-cert-tls = "server";
          remote-random = "yes";
          reneg-seconds = "0";
          service-type = "org.freedesktop.NetworkManager.openvpn";
          tls-cipher = "TLS-DHE-RSA-WITH-AES-256-GCM-SHA384";
          username = "$MULLVAD_USERNAME";
        };
        vpn-secrets = {
          password = "m";
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
          uuid = "eb59f995-a011-4665-a063-e572861080de";
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
