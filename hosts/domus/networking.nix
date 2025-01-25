{ config, pkgs, ... }:
let
  stationIF = "st0";
  RPI4MAC = "dc:a6:32:34:1a:d2";
  USB4MAC = "28:87:ba:a4:c3:cd";
  USB6MAC1 = "90:de:80:88:72:63";
  USB6MAC2 = "90:de:80:88:72:98";
in
{
  networking = {
    hostName = "domus";
    nameservers = [
      "9.9.9.9"
      "149.112.112.112"
    ];
    enableIPv6 = false;
    useNetworkd = true;
  };

  services.resolved.llmnr = "false";
  networking.firewall.allowedUDPPorts = [ 5353 ];
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
    };
  };

  systemd.network = {
    links."10-${stationIF}" = {
      matchConfig.PermanentMACAddress = USB6MAC2;
      linkConfig.Name = stationIF;
    };
    networks."10-${stationIF}" = {
      matchConfig.Name = stationIF;
      DHCP = "ipv4";
      dhcpV4Config = {
        UseDNS = false;
        Anonymize = false;
      };
    };
  };

  sops.secrets."system/networking/wpa_supplicant/secrets.conf" = { };
  networking.wireless = {
    enable = true;
    interfaces = [ stationIF ];
    secretsFile = config.sops.secrets."system/networking/wpa_supplicant/secrets.conf".path;
    networks = {
      rosetta = {
        pskRaw = "ext:secrets_psk_rosetta";
        priority = 99;
      };
      SFR_AFA3 = {
        pskRaw = "ext:secrets_psk_SFR_AFA3";
        priority = 10;
      };
    };
  };
}
