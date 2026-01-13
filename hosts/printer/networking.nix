{ config, ... }:
{
  sops.secrets."system/networking/wpa_supplicant/secrets.conf" = { };
  networking = {
    hostName = "printer";
    nameservers = [
      "9.9.9.9"
      "149.112.112.112"
    ];
    enableIPv6 = false;
    useNetworkd = true;
    wireless = {
      enable = true;
      networks = {
        rosetta.pskRaw = "ext:secrets_psk_rosetta";
      };
      secretsFile = config.sops.secrets."system/networking/wpa_supplicant/secrets.conf".path;
    };
  };
}
