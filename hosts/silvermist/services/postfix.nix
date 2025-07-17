{ config, ... }:
let
  dns = builtins.fromJSON (builtins.readFile ../../../dns.json);
  opendkimSocket = "/run/opendkim/opendkim.sock";
in
{
  environment.persistence.silvermist.directories = [ "/var/lib/postfix" ];

  sops.secrets."services/postfix/certs/acme/env" = { };
  security.acme.certs."${dns.subdomains.postfix}.${dns.zone}" = {
    dnsProvider = "cloudflare";
    environmentFile = config.sops.secrets."services/postfix/certs/acme/env".path;
    group = config.services.postfix.group;
  };

  services.postfix = {
    enable = true;
    hostname = "${dns.subdomains.postfix}.${dns.zone}";
    domain = dns.zone;
    config = {
      inet_interfaces = "loopback-only";

      smtpd_tls_cert_file = "/var/lib/acme/${dns.subdomains.postfix}.${dns.zone}/cert.pem";
      smtpd_tls_key_file = "/var/lib/acme/${dns.subdomains.postfix}.${dns.zone}/key.pem";
      smtpd_tls_security_level = "may";

      milter_protocol = "6";
      milter_default_action = "accept";
      smtpd_milters = "unix:${opendkimSocket}";
      non_smtpd_milters = "unix:${opendkimSocket}";
    };
  };

  sops.secrets."services/opendkim/selectors/${config.services.opendkim.selector}/private" = {
    owner = config.services.opendkim.user;
    path = "${config.services.opendkim.keyPath}/${config.services.opendkim.selector}.private";
  };
  services.opendkim = {
    enable = true;
    user = config.services.postfix.user;
    group = config.services.postfix.group;
    selector = "main";
    domains = "csl:${config.services.postfix.domain}";
    socket = "local:${opendkimSocket}";
  };
}
