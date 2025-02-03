{ config, ... }:
{
  sops.secrets."wpa.env" = { };
  networking = {
    hostName = "printer";
    nameservers = [
      "9.9.9.9"
      "149.112.112.112"
      "2620:fe::fe"
      "2620:fe::9"
    ];
    wireless = {
      enable = true;
      userControlled.enable = true;
      allowAuxiliaryImperativeNetworks = true;
      secretsFile = config.sops.secrets."wpa.env".path;
      networks = {
        rosetta.pskRaw = "ext:secrets_psk_rosetta";
        domus.pskRaw = "ext:secrets_psk_domus";
      };
    };
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
}
