{ config, ... }:
let
  dns = builtins.fromJSON (builtins.readFile ../dns.json);
  opendkimSocket = "/run/opendkim/opendkim.sock";
in
{
  services.postfix = {
    enable = true;
    hostname = dns.zone;
    domain = dns.zone;
    config = {
      inet_interfaces = "loopback-only";

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
