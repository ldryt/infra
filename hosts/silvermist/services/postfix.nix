{ config, lib, ... }:
let
  dns = builtins.fromJSON (builtins.readFile ../dns.json);
in
{
  services.postfix = {
    enable = true;
    hostname = dns.zone;
    config = {
      inet_interfaces = "loopback-only";

      milter_protocol = "6";
      milter_default_action = "accept";
      smtpd_milters = "unix:${config.services.opendkim.socket}";
      non_smtpd_milters = "unix:${config.services.opendkim.socket}";
    };
  };

  sops.secrets."services/opendkim/selectors/main/private".owner = config.services.postfix.user;
  services.opendkim = {
    enable = true;
    user = config.services.postfix.user;
    group = config.services.postfix.group;
    selector = "main";
    domains = config.services.postfix.domain;
    socket = "/run/opendkim/opendkim.sock";
  };
  systemd.services.opendkim.preStart = lib.mkForce ''
    install \
      -o ${config.services.postfix.user} \
      -g ${config.services.postfix.group} \
      -m0700 \
      -D \
      ${config.sops.secrets."services/opendkim/selectors/main/private".path} \
      ${config.services.opendkim.keyPath}/${config.services.opendkim.selector}.private
  '';
}
