{ ... }:
{
  networking.nameservers = [
    "::1"
    "127.0.0.1"
  ];

  # No nameservers overrides
  networking.networkmanager.dns = "none";
  networking.dhcpcd.extraConfig = "nohook resolv.conf";
  services.resolved.enable = false;

  # Enable mDNS resolving
  services.avahi = {
    enable = true;
    ipv6 = true;
    nssmdns6 = true;
    nssmdns4 = true;
  };

  services.dnscrypt-proxy2 = {
    enable = true;
    settings = {
      listen_addresses = [
        "[::1]:53"
        "127.0.0.1:53"
      ];

      # For portable devices, ipv6 is not guaranteed
      # ipv6_servers = true;

      require_dnssec = true;

      sources.public-resolvers = {
        urls = [
          "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md"
          "https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
        ];
        cache_file = "/var/lib/dnscrypt-proxy2/public-resolvers.md";
        minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
        refresh_delay = 48;
      };
    };
  };

  systemd.services.dnscrypt-proxy2.serviceConfig = {
    StateDirectory = "dnscrypt-proxy";
  };
}
