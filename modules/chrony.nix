{ ... }:
{
  services.chrony = {
    enable = true;
    enableNTS = true;
    servers = [
      "nts.netnod.se"
      "nts.teambelgium.net"
      "ntp.3eck.net"
      "time.cloudflare.com"
      "time.google.com"

      # In case of DNS failure
      "162.159.200.123" # time.cloudflare.com
      "94.224.65.118"   # nts.teambelgium.net
      "216.239.35.4"    # time.google.com
    ];
    extraConfig = ''
      makestep 1 -1
    '';
  };
}
