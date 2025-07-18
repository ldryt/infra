{ config, lib, ... }:
let
  dns = builtins.fromJSON (builtins.readFile ../../../dns.json);
in
{
  sops.secrets."services/mailserver/users/ldryt/password" = { };
  sops.secrets."services/postfix/certs/acme/env" = { };

  environment.persistence.silvermist.directories = [
    config.mailserver.mailDirectory
    config.mailserver.indexDir
    {
      directory = config.mailserver.dkimKeyDirectory;
      user = "opendkim";
      group = "opendkim";
      mode = "0750";
    }
    {
      directory = "/var/lib/rspamd";
      user = "rspamd";
      group = "rspamd";
      mode = "0700";
    }
  ];

  security.acme.certs."${dns.subdomains.mailserver}.${dns.zone}" = {
    dnsProvider = "desec";
    environmentFile = config.sops.secrets."services/postfix/certs/acme/env".path;
    group = config.services.postfix.group;
  };

  mailserver = {
    enable = true;
    fqdn = "${dns.subdomains.mailserver}.${dns.zone}";
    domains = [
      "ldryt.dev"
      "lucasladreyt.eu"
    ];

    loginAccounts = {
      "ldryt@ldryt.dev" = {
        hashedPasswordFile = config.sops.secrets."services/mailserver/users/ldryt/password".path;
        aliases = [
          "hello@ldryt.dev"
          "security@ldryt.dev"
          "postmaster@ldryt.dev"
        ];
      };
      "ldryt@lucasladreyt.eu" = {
        hashedPasswordFile = config.sops.secrets."services/mailserver/users/ldryt/password".path;
        aliases = [
          "hello@lucasladreyt.eu"
          "security@lucasladreyt.eu"
          "postmaster@lucasladreyt.eu"
        ];
      };
    };

    # https://nixos-mailserver.readthedocs.io/en/latest/options.html#cmdoption-arg-mailserver.certificateScheme
    certificateScheme = "acme";

    dkimKeyBits = 4096;

    fullTextSearch = {
      enable = true;
      autoIndex = true;
      enforced = "body";
    };
    indexDir = "/var/lib/dovecot/indices";
  };

  security.acme.acceptTerms = true;
  security.acme.defaults.email = lib.mkForce "security@ldryt.dev";

  ldryt-infra.backups.mailserver = {
    paths = [
      config.mailserver.mailDirectory
      config.mailserver.dkimKeyDirectory
    ];
  };
}
