{ config, pkgs, ... }:
let
  hidden = import ../../../secrets/obfuscated.nix;
  vaultwardenSubdomain = "pass";
  vaultwardenDataDir = "/var/lib/bitwarden_rs";
  vaultwardenBackupTmpDir = "/tmp/vaultwarden_backup";
in {
  services.vaultwarden = {
    enable = true;
    config = {
      DOMAIN = "https://${vaultwardenSubdomain}.${hidden.ldryt.host}";
      SIGNUPS_ALLOWED = "true";
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 44083;
    };
  };

  services.caddy.virtualHosts."${vaultwardenSubdomain}.${hidden.ldryt.host}".extraConfig =
    ''
      header {
        -Server
        Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
        X-Xss-Protection "1; mode=block"
        X-Content-Type-Options "nosniff"
        X-Frame-Options "DENY"
        Permissions-Policy interest-cohort=()
        Content-Security-Policy "upgrade-insecure-requests"
        Referrer-Policy "strict-origin-when-cross-origin"
        Cache-Control "public, max-age=15, must-revalidate"
        Feature-Policy "accelerometer 'none'; ambient-light-sensor 'none'; autoplay 'self'; camera 'none'; encrypted-media 'none'; fullscreen 'self'; geolocation 'none'; gyroscope 'none';       magnetometer 'none'; microphone 'none'; midi 'none'; payment 'none'; picture-in-picture *; speaker 'none'; sync-xhr 'none'; usb 'none'; vr 'none'"
      }

      reverse_proxy http://${config.services.vaultwarden.config.ROCKET_ADDRESS}:${
        toString config.services.vaultwarden.config.ROCKET_PORT
      }
    '';

  services.nginx = {
    virtualHosts."${vaultwardenSubdomain}.${hidden.ldryt.host}" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        recommendedProxySettings = true;
        proxyPass =
          "http://${config.services.vaultwarden.config.ROCKET_ADDRESS}:${
            toString config.services.vaultwarden.config.ROCKET_PORT
          }";
      };
    };
  };

  sops.secrets."backups/restic/vaultwarden/repositoryPass".owner =
    config.users.users.vaultwarden.name;
  sops.secrets."backups/restic/vaultwarden/sshKey".owner =
    config.users.users.vaultwarden.name;
  services.restic.backups.vaultwarden = {
    user = config.users.users.vaultwarden.name;
    # https://github.com/NixOS/nixpkgs/blob/592047fc9e4f7b74a4dc85d1b9f5243dfe4899e3/nixos/modules/services/security/vaultwarden/backup.sh
    backupPrepareCommand = ''
      ${pkgs.bash}/bin/bash -c '
        if ! mkdir -p "${vaultwardenBackupTmpDir}"; then
          echo "Could not create backup folder '${vaultwardenBackupTmpDir}'" >&2
          exit 1
        fi

        if [[ ! -f "${vaultwardenDataDir}"/db.sqlite3 ]]; then
          echo "Could not find SQLite database file '${vaultwardenDataDir}/db.sqlite3'" >&2
          exit 1
        fi

        ${pkgs.sqlite}/bin/sqlite3 "${vaultwardenDataDir}"/db.sqlite3 ".backup '${vaultwardenBackupTmpDir}/db.sqlite3'"
        cp "${vaultwardenDataDir}"/rsa_key.{der,pem,pub.der} "${vaultwardenBackupTmpDir}"
        cp -r "${vaultwardenDataDir}"/attachments "${vaultwardenBackupTmpDir}"
        cp -r "${vaultwardenDataDir}"/sends "${vaultwardenBackupTmpDir}"
      '
    '';
    paths = [ vaultwardenBackupTmpDir ];
    repository =
      "sftp:${hidden.backups.restic.vaultwarden.host}:restic-repo-vaultwarden";
    extraOptions = [
      "sftp.command='ssh ${hidden.backups.restic.vaultwarden.host} -p 23 -i ${
        config.sops.secrets."backups/restic/vaultwarden/sshKey".path
      } -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -s sftp'"
    ];
    initialize = true;
    passwordFile =
      config.sops.secrets."backups/restic/vaultwarden/repositoryPass".path;
    backupCleanupCommand = ''
      ${pkgs.bash}/bin/bash -c 'rm -rf "${vaultwardenBackupTmpDir}"'
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
