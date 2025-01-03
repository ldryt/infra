{ ... }:
{
  networking.nameservers = [
    "1.1.1.1"
    "9.9.9.9"
    "8.8.8.8"
  ];

  # No nameservers overrides
  networking.networkmanager.dns = "none";
  networking.dhcpcd.extraConfig = "nohook resolv.conf";
  services.resolved.enable = false;
  networking.resolvconf.enable = false;

  # Enable mDNS resolving
  services.avahi = {
    enable = true;
    ipv6 = true;
    nssmdns6 = true;
    nssmdns4 = true;
  };
}
