{ config, ... }:
let hidden = import ../../../secrets/obfuscated.nix;
in {
  services.authelia.instances."ldryt" = {
    enable = true;
    secrets = {
      jwtSecretFile = config.sops.secrets."services/authelia/jwtSecret".path;
      sessionSecretFile =
        config.sops.secrets."services/authelia/sessionSecret".path;
      storageEncryptionKeyFile =
        config.sops.secrets."services/authelia/storageEncryption".path;
      oidcHmacSecretFile =
        config.sops.secrets."services/authelia/oidcHmacSecret".path;
      oidcIssuerPrivateKeyFile =
        config.sops.secrets."services/authelia/oidcIssuerPrivateKey".path;
    };
    environmentVariables = {
      AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE =
        config.sops.secrets."services/authelia/smtpPassword".path;
    };
    settings = {
      theme = "auto";
      log = {
        level = "debug";
        format = "text";
      };
      server = {
        host = "localhost";
        port = 44081;
      };
      authentication_backend = {
        file = {
          path = config.sops.secrets."services/authelia/usersDB".path;
          search.email = true;
          password.algorithm = "argon2";
        };
      };
      totp.issuer = "iam.${hidden.ldryt.host}";
      duo_api.disable = true;
      password_policy = {
        zxcvbn = {
          enabled = true;
          min_score = 4;
        };
      };
      storage.local.path = "/var/lib/authelia-ldryt/db.sqlite3";
      session = {
        name = "ldryt_authelia_session";
        domain = "iam.${hidden.ldryt.host}";
        redis = { host = "/run/redis-authelia/redis.sock"; };
      };
      identity_providers.oidc = {
        cors.allowed_origins_from_client_redirect_uris = true;
        cors.endpoints =
          [ "authorization" "introspection" "revocation" "token" "userinfo" ];
      };
      notifier.smtp = {
        username = hidden.kiwi.authelia.smtp.username;
        sender = hidden.kiwi.authelia.smtp.sender;
        host = hidden.kiwi.authelia.smtp.host;
        port = hidden.kiwi.authelia.smtp.port;
      };
      access_control.default_policy = "one_factor";
    };
  };

  services.redis.servers."authelia" = {
    enable = true;
    user = config.services.authelia.instances.ldryt.user;
  };

  services.caddy.virtualHosts."iam.${hidden.ldryt.host}".extraConfig = ''
    reverse_proxy http://localhost:44081
  '';
}
