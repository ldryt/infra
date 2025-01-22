{ ... }:
let
  stationIF = "st0";
  accesspointIF = "ap0";
  apIp = "10.10.10.1";
  RPI4MAC = "dc:a6:32:34:1a:d2";
  USB4MAC = "28:87:ba:a4:c3:cd";
  USB6MAC1 = "90:de:80:88:72:63";
  USB6MAC2 = "90:de:80:88:72:98";
in
{
  systemd.network = {
    links."10-${accesspointIF}" = {
      matchConfig.PermanentMACAddress = USB6MAC1;
      linkConfig.Name = accesspointIF;
    };
    networks."10-${accesspointIF}" = {
      matchConfig.Name = accesspointIF;
      networkConfig = {
        Address = "${apIp}/24";
        DHCPServer = "yes";
        IPMasquerade = "ipv4";
        IPv4Forwarding = "yes";
      };
      dhcpServerConfig = {
        PoolOffset = 100;
        PoolSize = 64;
        EmitDNS = "yes";
        DNS = "9.9.9.9";
      };
    };
  };
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  networking.firewall.interfaces."${accesspointIF}".allowedUDPPorts = [ 67 ];

  services.hostapd = {
    enable = true;
    radios = {
      "${accesspointIF}" = {
        band = "5g";
        channel = 36;
        networks."${accesspointIF}" = {
          ssid = "domus";
          authentication.saePasswords = [{ password = "escalier"; }];
        };
      };
    };
  };
}
