{ config, ... }:
let
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

  boot.kernel.sysctl."net.ipv4.conf.all.forwarding" = 1;

  sops.secrets."services/hostapd/password" = { };
  services.hostapd = {
    enable = true;
    radios = {
      "${intf}" = {
        countryCode = "FR";
        band = "5g";
        channel = 36;
        wifi4 = {
          enable = true;
          capabilities = [
            "HT40+"
            "HT40-"
          ];
        };
        wifi5.enable = true;
        wifi6.enable = true;
        networks."${intf}" = {
          ssid = "tp420ia";
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
