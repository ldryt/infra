{ config, ... }:
{
  networking = {
    hostName = "printer";
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
    links."10-wlan0" = {
      matchConfig.PermanentMACAddress = "b8:27:eb:db:1e:3b";
      linkConfig.MACAddress = "de:ad:be:ef:00:01";
    };
    networks."10-wlan0" = {
      matchConfig.Name = "wlan0";
      DHCP = "ipv4";
      dhcpV4Config = {
        UseDNS = false;
        Anonymize = true;
      };
    };
  };

  sops.secrets."wpa.env" = { };
  networking.wireless = {
    enable = true;
    userControlled.enable = true;
    allowAuxiliaryImperativeNetworks = true;
    secretsFile = config.sops.secrets."wpa.env".path;
    networks = {
      rosetta.pskRaw = "ext:secrets_psk_rosetta";
      domus.pskRaw = "ext:secrets_psk_domus";
    };
  };

  sops.secrets."wgkey".owner = "systemd-network";
  systemd.network = {
    netdevs."10-printertunnel" = {
      netdevConfig = {
        Kind = "wireguard";
        Name = "printertunnel";
      };
      wireguardConfig = {
        PrivateKeyFile = config.sops.secrets."wgkey".path;
        ListenPort = 61495;
      };
      wireguardPeers = [
        {
          # silvermist
          PublicKey = "silv6SFoJoB7njsaIRTi55CaTb1RkRcM6pVx/WE5m38=";
          AllowedIPs = [ "10.22.22.1" ];
          Endpoint = "printer.ldryt.dev:62879";
          PersistentKeepalive = 2;
        }
      ];
    };
    networks."10-printertunnel" = {
      matchConfig.Name = "printertunnel";
      address = [ "10.22.22.122/24" ];
    };
  };
}
