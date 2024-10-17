{ pkgs, ... }:
{
  imports = [ ./nmprofiles.nix ];
  networking = {
    hostName = "tinkerbell";
    nameservers = [
      "127.0.0.1"
      "1.1.1.1"
    ];
    networkmanager = {
      enable = true;
      dns = "none";
      wifi = {
        powersave = true;
        macAddress = "random";
      };
      logLevel = "INFO";
    };
  };

  services.chrony = {
    enable = true;
    enableNTS = true;
    servers = [
      "nts.netnod.se"
      "nts.teambelgium.net"
      "time.cloudflare.com"
      "ntp.3eck.net"
    ];
    extraConfig = ''
      makestep 1 -1
    '';
  };

  services.dnscrypt-proxy2 = {
    enable = true;
    settings = {
      ipv6_servers = true;
      require_dnssec = true;

      sources.public-resolvers = {
        urls = [
          "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md"
          "https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
        ];
        cache_file = "/var/lib/dnscrypt-proxy2/public-resolvers.md";
        minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
      };
    };
  };

  systemd.services.dnscrypt-proxy2.serviceConfig = {
    StateDirectory = "dnscrypt-proxy";
  };
}
