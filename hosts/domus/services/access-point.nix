# https://www.mankier.com/5/systemd.network
# https://gist.github.com/gearhead/1941ae3a0efcf219efa97de7be2e9bc2
# https://man.archlinux.org/man/extra/iwd/iwd.ap.5.en
# https://www.mankier.com/5/tmpfiles.d
# https://www.mankier.com/5/systemd.netdev
# https://www.mankier.com/7/udev
# https://forum.archive.openwrt.org/viewtopic.php?id=68576
# https://en.wikipedia.org/wiki/Hexspeak

{ config, ... }:
let
  macs = builtins.fromJSON (builtins.readFile ../macs.json);
  ssid = "domus";
  ap0 = {
    mac = macs.onchip;
    intf = "ap0";
    vmac = "da:ba:d0:0c:cc:01";
    ip = "10.1.1.1";
  };
in
{
  systemd.network = {
    links = {
      "10-${ap0.intf}" = {
        matchConfig.PermanentMACAddress = ap0.mac;
        linkConfig = {
          Name = ap0.intf;
          MACAddress = ap0.vmac;
        };
      };
    };
    networks = {
      "10-${ap0.intf}" = {
        matchConfig.Name = ap0.intf;
        networkConfig = {
          Address = "${ap0.ip}/24";
          DHCPServer = "yes";
          IPMasquerade = "ipv4";
          IPv4Forwarding = "yes";
        };
        dhcpServerConfig = {
          PoolOffset = 100;
          PoolSize = 64;
          EmitDNS = "yes";
          DNS = ap0.ip;
        };
      };
    };
  };
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  networking.firewall.interfaces = {
    "${ap0.intf}" = {
      allowedTCPPorts = [ 53 ];
      allowedUDPPorts = [
        53
        67
      ];
    };
  };
  services.dnsmasq = {
    enable = true;
    resolveLocalQueries = false;
    settings = {
      listen-address = [
        ap0.ip
      ];
      bind-interfaces = true;
    };
  };
  systemd.services.dnsmasq.serviceConfig.RestartSec = "10s";

  sops.secrets."services/hostapd/password" = { };
  services.hostapd = {
    enable = true;
    radios = {
      "${ap0.intf}" = {
        countryCode = "FR";
        band = "2g";
        channel = 1;
        wifi6.enable = true;
        networks."${ap0.intf}" = {
          inherit ssid;
          authentication = {
            mode = "wpa2-sha1";
            wpaPasswordFile = config.sops.secrets."services/hostapd/password".path;
          };
        };
      };
    };
  };
}
