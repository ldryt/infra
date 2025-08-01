{ config, ... }:
let
  ssid = "tp420ia";
  mac = "58:cd:c9:3a:78:1b"; # mt7922
  intf = "ap0";
  ip = "192.168.144.1";
  mask = "24";
in
{
  systemd.network = {
    links = {
      "10-${intf}" = {
        matchConfig.PermanentMACAddress = mac;
        linkConfig.Name = intf;
      };
    };
    networks = {
      "10-${intf}" = {
        matchConfig.Name = intf;
        networkConfig = {
          Address = ip + "/" + mask;
          DHCPServer = "yes";
          IPMasquerade = "ipv4";
          IPv4Forwarding = "yes";
        };
        dhcpServerConfig = {
          PoolOffset = 10;
          PoolSize = 200;
          EmitDNS = "yes";
          DNS = "9.9.9.9";
        };
      };
    };
  };

  networking.firewall.interfaces."${intf}".allowedUDPPorts = [ 67 ];

  sops.secrets."services/hostapd/password" = { };
  services.hostapd = {
    enable = true;
    radios = {
      "${intf}" = {
        countryCode = "FR";
        band = "2g";
        channel = 1;
        wifi4 = {
          enable = true;
          capabilities = [
            "LDPC"
            "HT40+"
            "HT40-"
            "SHORT-GI-20"
            "SHORT-GI-40"
          ];
        };
        networks."${intf}" = {
          logLevel = 1;
          inherit ssid;
          authentication = {
            mode = "wpa3-sae-transition";
            saePasswordsFile = config.sops.secrets."services/hostapd/password".path;
            wpaPasswordFile = config.sops.secrets."services/hostapd/password".path;
            enableRecommendedPairwiseCiphers = true;
          };
        };
      };
    };
  };
}
