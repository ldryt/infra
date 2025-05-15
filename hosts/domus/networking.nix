{ config, ... }:
let
  macs = builtins.fromJSON (builtins.readFile ./macs.json);
  stationIF = "st0";
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

  # Avahi is more stable...
  services.resolved = {
    llmnr = "false";
    extraConfig = ''
      MulticastDNS=no
    '';
  };
  services.avahi = {
    enable = true;
    openFirewall = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
    };
  };

  systemd.network = {
    links."10-${stationIF}" = {
      matchConfig.PermanentMACAddress = macs.onchip;
      linkConfig = {
        Name = stationIF;
        MACAddress = "5a:f6:d6:96:07:35";
      };
    };
    networks."10-${stationIF}" = {
      matchConfig.Name = stationIF;
      DHCP = "ipv4";
      dhcpV4Config = {
        UseDNS = false;
        Anonymize = true;
      };
    };
  };

  sops.secrets."system/networking/wpa_supplicant/secrets.conf" = { };
  networking.wireless = {
    enable = true;
    interfaces = [ stationIF ];
    userControlled.enable = true;
    allowAuxiliaryImperativeNetworks = true;
    secretsFile = config.sops.secrets."system/networking/wpa_supplicant/secrets.conf".path;
    networks.rosetta.pskRaw = "ext:secrets_psk_rosetta";
  };
}
