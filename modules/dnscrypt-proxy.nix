{ ... }:
{
  services.dnscrypt-proxy = {
    enable = true;
    settings = {
      listen_addresses = [
        "127.0.0.1:53"
        "[::1]:53"
      ];
      http3 = true;
      server_names = [ "NextDNS-c1dca3" ];
      static = {
        "NextDNS-c1dca3" = {
          stamp = "sdns://AgEAAAAAAAAAAAAOZG5zLm5leHRkbnMuaW8HL2MxZGNhMw";
        };
      };
      sources = { };
    };
  };

  networking = {
    nameservers = [
      "127.0.0.1"
      "::1"
    ];
    networkmanager.dns = "none";
  };
}
