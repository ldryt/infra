{ config, ... }:
let
  ssid = "tp420ia";
  r24 = {
    intf = "ap24";
    addr = "192.168.24.0/24";
  };
  r5 = {
    intf = "ap5";
    addr = "192.168.5.0/24";
  };
in
{
  systemd.network = {
    netdevs = {
      "10-${r24.intf}" = {
        netdevConfig = {
          Kind = "wlan";
          Name = r24.intf;
          MACAddress = "ba:ba:ba:ba:ba:24";
        };
        wlanConfig = {
          PhysicalDevice = 0;
          Type = "ap";
        };
      };
      "10-${r5.intf}" = {
        netdevConfig = {
          Kind = "wlan";
          Name = r5.intf;
          MACAddress = "ba:ba:ba:ba:ba:05";
        };
        wlanConfig = {
          PhysicalDevice = 0;
          Type = "ap";
        };
      };
    };
    networks =
      let
        dhcpServerConfig = {
          PoolOffset = 10;
          PoolSize = 200;
          EmitDNS = "yes";
          DNS = "9.9.9.9";
        };
      in
      {
        "10-${r24.intf}" = {
          matchConfig.Name = r24.intf;
          networkConfig = {
            Address = r24.addr;
            DHCPServer = "yes";
            IPMasquerade = "ipv4";
            IPv4Forwarding = "yes";
          };
          inherit dhcpServerConfig;
        };
        "10-${r5.intf}" = {
          matchConfig.Name = r5.intf;
          networkConfig = {
            Address = r5.addr;
            DHCPServer = "yes";
            IPMasquerade = "ipv4";
            IPv4Forwarding = "yes";
          };
          inherit dhcpServerConfig;
        };
      };
  };

  networking.firewall.interfaces."${r24.intf}".allowedUDPPorts = [ 67 ];
  networking.firewall.interfaces."${r5.intf}".allowedUDPPorts = [ 67 ];

  sops.secrets."services/hostapd/password" = { };
  services.hostapd = {
    enable = true;
    radios =
      let
        countryCode = "FR";
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
        network = {
          logLevel = 1;
          inherit ssid;
          authentication = {
            mode = "wpa3-sae-transition";
            saePasswordsFile = config.sops.secrets."services/hostapd/password".path;
            wpaPasswordFile = config.sops.secrets."services/hostapd/password".path;
            enableRecommendedPairwiseCiphers = true;
          };
        };
      in
      {
        "${r24.intf}" = {
          inherit wifi4 countryCode;
          band = "2g";
          channel = 11;
          networks."${r24.intf}" = network;
        };
        "${r5.intf}" = {
          inherit wifi4 countryCode;
          band = "5g";
          channel = 36;
          wifi5 = {
            enable = true;
            operatingChannelWidth = "160";
            capabilities = [
              "SHORT-GI-80"
            ];
          };
          networks."${r5.intf}" = network;
        };
      };
  };
}
