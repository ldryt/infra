{
  config,
  pkgs,
  vars,
  ...
}:
{
  services.vaultwarden = {
    enable = true;
    config = {
      DOMAIN = "https://${vars.services.vaultwarden.subdomain + "." + vars.zone}";
      SIGNUPS_ALLOWED = "true";
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 44083;
    };
  };

  services.caddy.virtualHosts."${
    vars.services.vaultwarden.subdomain + "." + vars.zone
  }".extraConfig = ''
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

    reverse_proxy http://${config.services.vaultwarden.config.ROCKET_ADDRESS}:${toString config.services.vaultwarden.config.ROCKET_PORT}
  '';

  services.nginx = {
    virtualHosts."${vars.services.vaultwarden.subdomain + "." + vars.zone}" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        recommendedProxySettings = true;
        proxyPass = "http://${config.services.vaultwarden.config.ROCKET_ADDRESS}:${toString config.services.vaultwarden.config.ROCKET_PORT}";
      };
    };
  };

  sops.secrets."backups/restic/vaultwarden/repositoryPass".owner =
    config.users.users.vaultwarden.name;
  sops.secrets."backups/restic/vaultwarden/sshKey".owner = config.users.users.vaultwarden.name;
  services.restic.backups.vaultwarden = {
    user = config.users.users.vaultwarden.name;
    # https://github.com/NixOS/nixpkgs/blob/592047fc9e4f7b74a4dc85d1b9f5243dfe4899e3/nixos/modules/services/security/vaultwarden/backup.sh
    backupPrepareCommand = ''
      ${pkgs.bash}/bin/bash -c '
        if ! mkdir -p "${vars.services.vaultwarden.backups.tmpDir}"; then
          echo "Could not create backup folder '${vars.services.vaultwarden.backups.tmpDir}'" >&2
          exit 1
        fi

        if [[ ! -f "${vars.services.vaultwarden.dataDir}"/db.sqlite3 ]]; then
          echo "Could not find SQLite database file '${vars.services.vaultwarden.dataDir}/db.sqlite3'" >&2
          exit 1
        fi

        ${pkgs.sqlite}/bin/sqlite3 "${vars.services.vaultwarden.dataDir}"/db.sqlite3 ".backup '${vars.services.vaultwarden.backups.tmpDir}/db.sqlite3'"
        cp "${vars.services.vaultwarden.dataDir}"/rsa_key.{der,pem,pub.der} "${vars.services.vaultwarden.backups.tmpDir}"
        cp -r "${vars.services.vaultwarden.dataDir}"/attachments "${vars.services.vaultwarden.backups.tmpDir}"
        cp -r "${vars.services.vaultwarden.dataDir}"/sends "${vars.services.vaultwarden.backups.tmpDir}"
      '
    '';
    paths = [ vars.services.vaultwarden.backups.tmpDir ];
    repository = "sftp:${
      vars.sensitive.backups.user + "@" + vars.sensitive.backups.host
    }:restic-repo-vaultwarden";
    extraOptions = [
      "sftp.command='ssh ${vars.sensitive.backups.user + "@" + vars.sensitive.backups.host} -p 23 -i ${
        config.sops.secrets."backups/restic/vaultwarden/sshKey".path
      } -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -s sftp'"
    ];
    initialize = true;
    passwordFile = config.sops.secrets."backups/restic/vaultwarden/repositoryPass".path;
    backupCleanupCommand = ''
      ${pkgs.bash}/bin/bash -c 'rm -rf "${vars.services.vaultwarden.backups.tmpDir}"'
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
