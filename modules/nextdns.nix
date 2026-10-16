{ pkgs, ... }:
{
  services.nextdns = {
    enable = true;
    arguments = [
      "-profile=c1dca3"
      "-listen=127.0.0.1:53"
      "-listen=[::1]:53"
      "-cache-size=16MB"
      "-detect-captive-portals=true"
      "-auto-activate=false"
    ];
  };

  networking = {
    nameservers = [
      "127.0.0.1"
      "::1"
    ];
    networkmanager.dns = "none";
  };

  systemd.services.nextdns = {
    # NextDNS uses nmcli to discover DHCP DNS servers for captive portals.
    path = [ pkgs.networkmanager ];
    serviceConfig.Restart = "on-failure";
  };
}
