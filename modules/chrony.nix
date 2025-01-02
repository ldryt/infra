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

      # In case of DNS failure
      "162.159.200.123" # time.cloudflare.com
      "94.224.65.118"   # nts.teambelgium.net
    ];
    extraConfig = ''
      makestep 1 -1
    '';
  };
}
