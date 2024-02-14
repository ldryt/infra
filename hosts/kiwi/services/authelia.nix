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
          password = {
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
        };
      };
      password_policy = {
        zxcvbn = {
          enabled = true;
          min_score = 4;
        };
      };
      storage.postgres = {
        host = "localhost";
        port = 44051;
        database = "authelia";
        username = "authelia";
        password =
          config.sops.secrets."services/authelia/postgresPassword".path;
      };
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
      notifier.filesystem.filename = "/tmp/authelia-notification";
      access_control.default_policy = "one_factor";
    };
  };

  services.redis.servers."authelia" = {
    enable = true;
    user = config.services.authelia.instances.ldryt.user;
  };

  virtualisation.oci-containers.containers = {
    "authelia-db" = {
      image =
        "docker.io/library/postgres@sha256:17eb369d9330fe7fbdb2f705418c18823d66322584c77c2b43cc0e1851d01de7";
      environment = {
        POSTGRES_PASSWORD_FILE = "/pass";
        POSTGRES_USER = "authelia";
        PGPORT = "44051";
      };
      volumes = [
        "authelia-db-data:/var/lib/postgresql"
        "${config.sops.secrets."services/authelia/postgresPassword".path}:/pass"
      ];
      extraOptions = [ "--network=host" ];
    };
  };

  services.nginx = {
    virtualHosts."iam.${hidden.ldryt.host}" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        recommendedProxySettings = true;
        proxyPass = "http://localhost:44081";
        extraConfig = ''
          proxy_buffers 4 256k;
          proxy_buffer_size 128k;
          proxy_busy_buffers_size 256k;
        '';
      };
    };
  };
}
