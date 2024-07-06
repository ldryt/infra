{ ... }:
{
  networking.nameservers = [
    "9.9.9.11#dns.quad9.net"
    "149.112.112.112#dns.quad9.net"
    "2620:fe::fe#dns.quad9.net"
    "2620:fe::9#dns.quad9.net"
  ];

  services.resolved = {
    enable = true;
    llmnr = "false";
    dnsovertls = "opportunistic";
    dnssec = "allow-downgrade";
    domains = [ "~." ];
    fallbackDns = [ "1.1.1.1#one.one.one.one" "1.0.0.1#one.one.one.one" ];
    extraConfig = ''
      MulticastDNS=yes
    '';
  };
}
