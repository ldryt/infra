{ lib, ... }:
{
  imports = [ ./dns.nix ];

  networking.nameservers = lib.mkForce [
    "::1"
    "127.0.0.1"
  ];

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
        minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
        cache_file = "/var/lib/dnscrypt-proxy/public-resolvers.md";
      };
    };
  };
}
