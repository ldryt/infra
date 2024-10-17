{ ... }:
{
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
}
