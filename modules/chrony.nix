{ ... }:
{
  services.chrony = {
    enable = true;
    servers = [
      "132.163.96.1"
      "132.163.97.1"
      "104.16.133.229"
      "194.58.200.20"
      "ntp.se"
      "ntp.3eck.net"
      "time.cloudflare.com"
      "time.nist.gov"
    ];
  };
}
