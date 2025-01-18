{ ... }:
{
  networking.nameservers = [ "9.9.9.9" ];

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
