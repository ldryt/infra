{ config, ... }:
{
  sops.secrets."wpa_supplicant.env" = { };
  networking = {
    hostName = "v03037";
    wireless = {
      enable = true;
      secretsFile = config.sops.secrets."wpa_supplicant.env".path;
      networks = {
        "ext:primary_essid".psk = "ext:primary_psk";
        "ext:secondary_essid".psk = "ext:secondary_psk";
      };
    };
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
  };
}
