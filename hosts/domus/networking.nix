{ config, ... }:
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

  systemd.network = {
    networks."10-wlan0" = {
      matchConfig.Name = "wlan0";
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
    interfaces = [ "wlan0" ];
    userControlled.enable = true;
    allowAuxiliaryImperativeNetworks = true;
    secretsFile = config.sops.secrets."system/networking/wpa_supplicant/secrets.conf".path;
    networks.rosetta.pskRaw = "ext:secrets_psk_rosetta";
  };
}
