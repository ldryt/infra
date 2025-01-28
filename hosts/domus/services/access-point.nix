# https://www.mankier.com/5/systemd.network
# https://gist.github.com/gearhead/1941ae3a0efcf219efa97de7be2e9bc2
# https://man.archlinux.org/man/extra/iwd/iwd.ap.5.en
# https://www.mankier.com/5/tmpfiles.d
# https://www.mankier.com/5/systemd.netdev
# https://www.mankier.com/7/udev
# https://forum.archive.openwrt.org/viewtopic.php?id=68576

{ config, pkgs, ... }:
let
  ap = {
    mac = USB6MAC1;
    intf = "ap0";
    phyintf = "phy37";
    private = {
      vintf = "ap0-private";
      vmac = "aa:ff:ff:ff:ff:01";
      ip = "10.1.1.1";
    };
    open = {
      vintf = "ap0-open";
      vmac = "aa:ff:ff:ff:ff:99";
      ip = "10.99.99.1";
    };
  };

  RPI4MAC = "dc:a6:32:34:1a:d2";
  USB4MAC = "28:87:ba:a4:c3:cd";
  USB6MAC1 = "90:de:80:88:72:63";
  USB6MAC2 = "90:de:80:88:72:98";
in
{
  systemd.network = {
    netdevs = {
      "10-${ap.private.vintf}" = {
        netdevConfig = {
          Name = ap.private.vintf;
          MACAddress = ap.private.vmac;
          Kind = "wlan";
        };
        wlanConfig = {
          #PhysicalDevice = ap.phyintf;
          PhysicalDevice = "phy2";
          Type = "ap";
        };
      };
      "10-${ap.open.vintf}" = {
        netdevConfig = {
          Name = ap.open.vintf;
          MACAddress = ap.open.vmac;
          Kind = "wlan";
        };
        wlanConfig = {
          #PhysicalDevice = ap.phyintf;
          PhysicalDevice = "phy2";
          Type = "ap";
        };
      };
    };
    networks = {
      "10-${ap.private.vintf}" = {
        matchConfig.Name = ap.private.vintf;
        networkConfig = {
          Address = "${ap.private.ip}/24";
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
  };
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  networking.firewall.interfaces."${ap.private.vintf}".allowedUDPPorts = [ 67 ];

  sops.secrets."services/hostapd/password" = { };
  services.hostapd = {
    enable = true;
    radios = {
      "${ap.private.vintf}" = {
        countryCode = "FR";
        band = "5g";
        channel = 36;
        networks."${ap.private.vintf}" = {
          ssid = "domus";
          authentication.saePasswordsFile = config.sops.secrets."services/hostapd/password".path;
        };
      };
      "${ap.open.vintf}" = {
        countryCode = "FR";
        band = "2g";
        channel = 1;
        networks."${ap.open.vintf}" = {
          ssid = "domus-open";
          authentication.mode = "none";
        };
      };
    };
  };
}
