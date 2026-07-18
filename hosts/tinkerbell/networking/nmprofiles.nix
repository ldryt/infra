{ config, ... }:
let
  nameToUuid =
    with builtins;
    name:
    let
      h = hashString "md5" name;
    in
    "${substring 0 8 h}-${substring 8 4 h}-${substring 12 4 h}-${substring 16 4 h}-${substring 20 12 h}";
  mkWifi = ssid: psk: {
    connection = {
      id = ssid;
      uuid = nameToUuid ssid;
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
  mkSaeWifi = ssid: psk: {
    connection = {
      id = ssid;
      uuid = nameToUuid ssid;
      type = "wifi";
    };
    wifi = {
      mode = "infrastructure";
      inherit ssid;
    };
    wifi-security = {
      key-mgmt = "sae";
      inherit psk;
    };
  };
  mkEapWifi = ssid: id: pass: {
    "802-1x" = {
      eap = "peap";
      identity = id;
      password = pass;
      phase2-auth = "mschapv2";
    };
    connection = {
      id = ssid;
      uuid = nameToUuid ssid;
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
  mkWireguard =
    {
      name,
      address,
      privateKey,
      peerPubKey,
      endpoint,
      allowedIPs ? "0.0.0.0/0;",
      presharedKey ? null,
      mtu ? "1420",
      autoconnect ? false,
    }:
    {
      connection = {
        id = name;
        interface-name = name;
        type = "wireguard";
        inherit autoconnect;
      };
      ipv4 = {
        address1 = address;
        method = "manual";
      };
      ipv6 = {
        method = "disabled";
      };
      wireguard = {
        inherit mtu;
        private-key = privateKey;
      };
      "wireguard-peer.${peerPubKey}" = {
        allowed-ips = allowedIPs;
        inherit endpoint;
      }
      // (
        if presharedKey != null then
          {
            preshared-key = presharedKey;
            preshared-key-flags = "0";
          }
        else
          { }
      );
    };
in
{
  sops.secrets."system/NetworkManager/profiles/env" = { };
  networking.networkmanager.ensureProfiles = {
    environmentFiles = [ config.sops.secrets."system/NetworkManager/profiles/env".path ];
    profiles = {
      wg_GNB = mkWireguard {
        name = "wg_GNB";
        address = "192.168.27.65/32";
        privateKey = "$wg_GNB_PRIVATE_KEY";
        peerPubKey = "auwq1FbYBSiMBTktf105iLyIv6CRPIK5KGy9zvdVNhE=";
        endpoint = "$wg_GNB_ENDPOINT";
        allowedIPs = "0.0.0.0/0;192.168.27.64/27;192.168.0.0/24;";
        presharedKey = "$wg_GNB_PRESHARED_KEY";
        mtu = "1360";
      };
      wg_ORY = mkWireguard {
        name = "wg_ORY";
        address = "192.168.27.65/32";
        privateKey = "$wg_ORY_PRIVATE_KEY";
        peerPubKey = "J+mdhyF9Qk4I7R7NbF++bGW6rNI7qQVx/DnrX5cihno=";
        endpoint = "$wg_ORY_ENDPOINT";
        allowedIPs = "0.0.0.0/0;192.168.27.64/27;192.168.1.0/24;";
        presharedKey = "$wg_ORY_PRESHARED_KEY";
        mtu = "1360";
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
      ORY = mkSaeWifi "$ORY_SSID" "$ORY_PWD";
      rosetta = mkWifi "rosetta" "$ROSETTA_PWD";
      tp420ia = mkWifi "tp420ia" "$TP420IA_PWD";
      IONIS = mkEapWifi "IONIS" "$eduroam_ID" "$eduroam_PWD";
      Eduroam = mkEapWifi "Eduroam" "$eduroam_ID" "$eduroam_PWD";
      eduroam = mkEapWifi "eduroam" "$eduroam_ID" "$eduroam_PWD";
    };
  };
}
