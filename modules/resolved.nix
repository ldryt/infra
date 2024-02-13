{ ... }: {
  services.resolved = {
    enable = true;
    dnssec = "true";
    domains = [ "~." ];
    extraConfig = ''
      DNSOverTLS=yes
    '';
  };
  networking.nameservers =
    [ "1.1.1.1#one.one.one.one" "1.0.0.1#one.one.one.one" ];
  networking.networkmanager.dns = "systemd-resolved";
}
