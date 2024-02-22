{ config, pkgs, ... }:
let
  hidden = import ../../../secrets/obfuscated.nix;
  autheliaBackupTmpDir = "/tmp/authelia_backup";
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
      authentication_backend.file = {
        path = config.sops.secrets."services/authelia/usersDB".path;
        search.email = true;
        password.algorithm = "argon2";
      };
      totp.issuer = "iam.${hidden.ldryt.host}";
      duo_api.disable = true;
      password_policy.zxcvbn = {
        enabled = true;
        min_score = 4;
      };
      storage.local.path = "/var/lib/authelia-ldryt/db.sqlite3";
      session = {
        name = "ldryt_authelia_session";
        domain = "iam.${hidden.ldryt.host}";
        redis.host = "/run/redis-authelia/redis.sock";
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
    # https://github.com/authelia/authelia/issues/3277#issuecomment-1370168028
    uri /api/oidc/authorization replace &prompt=select_account%20consent ""

    reverse_proxy http://${
      config.services.authelia.instances."ldryt".settings.server.host
    }:${
      toString config.services.authelia.instances."ldryt".settings.server.port
    }
  '';

  services.restic.backups.authelia = {
    user = config.services.authelia.instances."ldryt".user;
    backupPrepareCommand = ''
      ${pkgs.bash}/bin/bash -c '
        if ! mkdir -p "${autheliaBackupTmpDir}"; then
          echo "Could not create backup folder '${autheliaBackupTmpDir}'" >&2
          exit 1
        fi

        if [[ ! -f "${
          config.services.authelia.instances."ldryt".settings.storage.local.path
        }" ]]; then
          echo "Could not find SQLite database file '${
            config.services.authelia.instances."ldryt".settings.storage.local.path
          }'" >&2
          exit 1
        fi

        ${pkgs.sqlite}/bin/sqlite3 "${
          config.services.authelia.instances."ldryt".settings.storage.local.path
        }" ".backup '${autheliaBackupTmpDir}/db.sqlite3'"
      '
    '';
    paths = [ autheliaBackupTmpDir ];
    repository =
      "sftp:${hidden.backups.restic.authelia.host}:restic-repo-authelia";
    extraOptions = [
      "sftp.command='ssh ${hidden.backups.restic.authelia.host} -p 23 -i ${
        config.sops.secrets."backups/restic/authelia/sshKey".path
      } -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -s sftp'"
    ];
    initialize = true;
    passwordFile =
      config.sops.secrets."backups/restic/authelia/repositoryPass".path;
    backupCleanupCommand = ''
      ${pkgs.bash}/bin/bash -c 'rm -rf "${autheliaBackupTmpDir}"'
    '';
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 8"
      "--keep-monthly 12"
      "--keep-yearly 100"
    ];
    timerConfig = {
      OnCalendar = "daily";
      RandomizedDelaySec = "6h";
      Persistent = true;
    };
  };
}
