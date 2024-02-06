{ config, ... }:
let secrets = import ../../../secrets/git-crypt.nix;
in
{
  sops.secrets."authelia/ldryt/jwtSecret" = {};
  sops.secrets."authelia/ldryt/sessionSecret" = {};
  sops.secrets."authelia/ldryt/storageEncryption" = {};
  sops.secrets."authelia/ldryt/oidcHmacSecret" = {};
  sops.secrets."authelia/ldryt/oidcIssuerPrivateKey" = {};
  sops.secrets."authelia/ldryt/usersDB" = {};
  sops.secrets."authelia/ldryt/postgresPassword" = {};

  services.authelia.instances."ldryt" = {
    enable = true;
    secrets = {
      jwtSecretFile = config.sops.secrets."authelia/ldryt/jwtSecret".path;
      sessionSecretFile = config.sops.secrets."authelia/ldryt/sessionSecret".path;
      storageEncryptionKeyFile = config.sops.secrets."authelia/ldryt/storageEncryption".path;
      oidcHmacSecretFile = config.sops.secrets."authelia/ldryt/oidcHmacSecret".path;
      oidcIssuerPrivateKeyFile = config.sops.secrets."authelia/ldryt/oidcIssuerPrivateKey".path;
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
          path = config.sops.secrets."authelia/ldryt/usersDB".path;
          search.email = true;
        };
        algorithm = "argon2";
        argon2 = {
          variant = "argon2id";
          iterations = 3;
          memory = 12288;
          parallelism = 3;
          key_length = 32;
          salt_length = 16;
        };
      };
      password_policy = {
        zxcvbn = {
          enable = true;
          min_score = 4;
        };
      };
      storage.postgres = {
        host = "localhost";
        port = 44051;
        database = "authelia";
        username = "authelia";
      };
      session = {
        name = "ldryt_authelia_session";
        domain = "iam." + secrets.ldryt.host;
        redis = {
          host = "/run/redis-authelia/redis.sock";
        };
      };
      identity_providers.oidc = {
        cors.allowed_origins_from_client_redirect_uris = true;
        cors.endpoints = [
          "authorization"
          "introspection"
          "revocation"
          "token"
          "userinfo"
        ];
      };
    };
  };

  services.redis.servers."authelia".enable = true;

  virtualisation.oci-containers.containers = {
    "authelia-db" = {
      image = "docker.io/library/postgres@sha256:17eb369d9330fe7fbdb2f705418c18823d66322584c77c2b43cc0e1851d01de7";
      environment = {
        POSTGRES_PASSWORD_FILE = config.sops.secrets."authelia/ldryt/postgresPassword".path;
        POSTGRES_USER = "authelia";
      };
    };
  };

  services.nginx = {
    virtualHosts.${"iam." + secrets.ldryt.host} = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        recommendedProxySettings = true;
        proxyPass = "http://localhost:9091";
        extraConfig = ''
          proxy_buffers 4 256k;
          proxy_buffer_size 128k;
          proxy_busy_buffers_size 256k;
        '';
      };
    };
  };
}
