{
  config,
  lib,
  ...
}:
{
  services.chrony = {
    enable = true;
    enableNTS = true;
    servers = lib.mkDefault [
      "ntp.obspm.fr"
      "nts.netnod.se"
      "time.cloudflare.com"
    ];
    extraConfig = ''
      server ntp.ovh.net iburst
      server ntp-01.jeffgeerling.com iburst
    ''
    + ''
      allow
      ratelimit
    ''
    + (
      let
        cert = config.security.acme.certs.${config.ldryt-infra.dns.records.time};
      in
      ''
        ntsservercert ${cert.directory}/fullchain.pem
        ntsserverkey ${cert.directory}/key.pem
      ''
    );
  };

  sops.secrets."system/ntp-pool/acme/token" = { };

  security.acme.certs.${config.ldryt-infra.dns.records.time} = {
    dnsProvider = "desec";
    credentialFiles.DESEC_TOKEN_FILE = config.sops.secrets."system/ntp-pool/acme/token".path;
    group = "chrony";
    reloadServices = [ "chronyd.service" ];
  };

  systemd.services.chronyd = {
    requires = [ "acme-${config.ldryt-infra.dns.records.time}.service" ];
    after = [ "acme-${config.ldryt-infra.dns.records.time}.service" ];
  };

  networking.firewall = {
    allowedUDPPorts = [ 123 ];
    allowedTCPPorts = [ 4460 ];
  };

  ldryt-infra.persist.directories = [
    {
      directory = config.services.chrony.directory;
      user = "chrony";
      group = "chrony";
      mode = "0750";
    }
  ];
}
