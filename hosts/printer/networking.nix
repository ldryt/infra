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

  sops.secrets."wgkey" = { };
  networking.firewall.allowedUDPPorts = [ 51820 ];
  networking.wireguard = {
    enable = true;
    interfaces = {
      printertunnel = {
        ips = [ "10.22.22.122/24" ];
        listenPort = 51820;
        privateKeyFile = config.sops.secrets."wgkey".path;
        peers = [
          {
          # silvermist
          publicKey = "silv6SFoJoB7njsaIRTi55CaTb1RkRcM6pVx/WE5m38=";
          allowedIPs = [ "10.22.22.1" ];
          endpoint = "printer.ldryt.dev:62879";
          persistentKeepalive = 2;
        }
      ];
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
