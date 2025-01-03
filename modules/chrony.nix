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
    ];
    extraConfig = ''
      makestep 1 -1
    '';
  };
}
