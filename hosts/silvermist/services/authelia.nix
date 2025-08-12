{ config, ... }:
let
  autheliaInternalAddress = "localhost:44092";
  dataDir = "/var/lib/authelia-${config.services.authelia.instances.main.name}";
in
{
  environment.persistence.silvermist.directories = [ dataDir ];

  sops.secrets."services/authelia/users".owner = config.services.authelia.instances.main.user;
  sops.secrets."services/authelia/jwtSecret".owner = config.services.authelia.instances.main.user;
  sops.secrets."services/authelia/storageEncryptionKey".owner =
    config.services.authelia.instances.main.user;
  sops.secrets."services/authelia/sessionSecret".owner = config.services.authelia.instances.main.user;
  sops.secrets."services/authelia/oidcHmacSecret".owner =
    config.services.authelia.instances.main.user;
  sops.secrets."services/authelia/oidcIssuerPrivateKey".owner =
    config.services.authelia.instances.main.user;
  services.authelia.instances.main = {
    enable = true;

    environmentVariables = {
      AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE =
        config.sops.secrets."services/authelia/mail/clearPassword".path;
    };

    secrets = {
      jwtSecretFile = config.sops.secrets."services/authelia/jwtSecret".path;
      storageEncryptionKeyFile = config.sops.secrets."services/authelia/storageEncryptionKey".path;
      sessionSecretFile = config.sops.secrets."services/authelia/sessionSecret".path;
      oidcHmacSecretFile = config.sops.secrets."services/authelia/oidcHmacSecret".path;
      oidcIssuerPrivateKeyFile = config.sops.secrets."services/authelia/oidcIssuerPrivateKey".path;
    };

    settings = {
      theme = "auto";

      log = {
        level = "info";
        format = "text";
      };

      server.address = "tcp://${autheliaInternalAddress}/";

      storage.local.path = "${dataDir}/db.sqlite3";

      session.cookies = [
        {
          domain = config.ldryt-infra.dns.zone;
          authelia_url = "https://${config.ldryt-infra.dns.records.authelia}";
        }
      ];

      identity_providers.oidc = {
        lifespans = {
          access_token = "1h";
          refresh_token = "3d";
        };
        cors = {
          endpoints = [
            "authorization"
            "token"
            "revocation"
            "introspection"
          ];
          allowed_origins_from_client_redirect_uris = true;
        };
      };

      access_control.default_policy = "two_factor";

      authentication_backend = {
        file.path = config.sops.secrets."services/authelia/users".path;
      };

      totp.issuer = config.ldryt-infra.dns.records.authelia;

      notifier.smtp = {
        address = "submissions://${config.ldryt-infra.dns.records.mailserver}:465";
        identifier = "${config.ldryt-infra.dns.records.mailserver}";
        sender = "Authelia <auth@ldryt.dev>";
        username = "auth@ldryt.dev";
      };
    };
  };

  sops.secrets."services/authelia/mail/clearPassword".owner =
    config.services.authelia.instances.main.user;

  sops.secrets."services/authelia/mail/hashedPassword" = { };
  mailserver.loginAccounts."auth@ldryt.dev" = {
    hashedPasswordFile = config.sops.secrets."services/authelia/mail/hashedPassword".path;
    sendOnly = true;
  };

  services.nginx.virtualHosts."${config.ldryt-infra.dns.records.authelia}" = {
    enableACME = true;
    forceSSL = true;
    kTLS = true;
    locations."/".proxyPass = "http://${autheliaInternalAddress}";
  };

  sops.secrets."backups/restic/repos/authelia/password" = { };
  ldryt-infra.backups.repos.authelia = {
    passwordFile = config.sops.secrets."backups/restic/repos/authelia/password".path;
    paths = [ config.services.authelia.instances.main.settings.storage.local.path ];
  };
}
