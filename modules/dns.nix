{ ... }:
{
  services.dnscrypt-proxy2 = {
    enable = true;
    settings = {
      http3 = true;
      server_names = [ "NextDNS-c1dca3" ];
      static = {
        "NextDNS-c1dca3" = {
          stamp = "sdns://AgEAAAAAAAAAAAAOZG5zLm5leHRkbnMuaW8HL2MxZGNhMw";
        };
      };
    };
  };

  networking.nameservers = [
    "127.0.0.1"
    "::1"
  ];

  # No nameservers overrides
  networking.networkmanager.dns = "none";
  networking.dhcpcd.extraConfig = "nohook resolv.conf";
  services.resolved.enable = false;

  # Enable mDNS resolving
  services.avahi = {
    enable = true;
    nssmdns4 = true;
  };
}
