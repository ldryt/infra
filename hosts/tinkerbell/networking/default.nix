{ ... }:
{
  imports = [ ./nmprofiles.nix ];
  networking = {
    hostName = "tinkerbell";
    networkmanager = {
      enable = true;
      dns = "systemd-resolved";
      wifi = {
        powersave = true;
        macAddress = "random";
      };
      logLevel = "INFO";
    };
    timeServers = [
      "europe.pool.ntp.org"
      "time.cloudflare.com"
    ];
    nameservers = [
      "2606:4700:4700::1111#cloudflare-dns.com"
      "2606:4700:4700::1001#cloudflare-dns.com"
      "1.1.1.1#cloudflare-dns.com"
      "1.0.0.1#cloudflare-dns.com"
    ];
  };
  services.resolved = {
    enable = true;
    dnssec = "true";
    domains = [ "~." ];
    fallbackDns = [ "1.1.1.1" ];
    extraConfig = ''
      DNSOverTLS=yes
    '';
  };
}
