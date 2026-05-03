{ config, ... }:
let
  mkWifi = ssid: psk: {
    connection = {
      id = ssid;
      type = "wifi";
    };
    wifi = {
      mode = "infrastructure";
      inherit ssid;
    };
    wifi-security = {
      key-mgmt = "wpa-psk";
      inherit psk;
    };
  };
  mkEapWifi = ssid: id: pass: {
    "802-1x" = {
      eap = "peap;";
      identity = id;
      password = pass;
      phase2-auth = "mschapv2";
    };
    connection = {
      id = ssid;
      type = "wifi";
    };
    wifi = {
      mode = "infrastructure";
      inherit ssid;
    };
    wifi-security = {
      auth-alg = "open";
      key-mgmt = "wpa-eap";
    };
  };
in
{
  sops.secrets."system/NetworkManager/profiles/env" = { };
  networking.networkmanager.ensureProfiles = {
    environmentFiles = [ config.sops.secrets."system/NetworkManager/profiles/env".path ];
    profiles = {
      wg_GNB = {
        connection = {
          id = "wg_GNB";
          interface-name = "wg_GNB";
          type = "wireguard";
          autoconnect = false;
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
      LYS = mkWifi "$LYS_SSID" "$LYS_PWD" // {
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
      };
      ANR = mkWifi "$ANR_SSID" "$ANR_PWD";
      MAKER = mkWifi "$MAKER_SSID" "$MAKER_PWD";
      VNO = mkWifi "$VNO_SSID" "$VNO_PWD";
      GNB = mkWifi "$GNB_SSID" "$GNB_PWD";
      rosetta = mkWifi "rosetta" "$ROSETTA_PWD";
      tp420ia = mkWifi "tp420ia" "$TP420IA_PWD";
      IONIS = mkEapWifi "IONIS" "$eduroam_ID" "$eduroam_PWD";
      Eduroam = mkEapWifi "Eduroam" "$eduroam_ID" "$eduroam_PWD";
      eduroam = mkEapWifi "eduroam" "$eduroam_ID" "$eduroam_PWD";
    };
  };
}
