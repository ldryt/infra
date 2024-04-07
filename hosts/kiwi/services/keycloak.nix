{
  config,
  vars,
  pkgs,
  ...
}:
{
  sops.secrets."services/keycloak/db/password" = { };

  services.keycloak = {
    enable = true;
    initialAdminPassword = "matchbook-purse3";
    settings = {
      hostname = "${vars.services.keycloak.subdomain}.${vars.zone}";
      hostname-strict-backchannel = true;
      http-host = "127.0.0.1";
      http-port = 44085;
      proxy = "edge";
    };
    database = {
      createLocally = true;
      type = "mariadb";
      passwordFile = config.sops.secrets."services/keycloak/db/password".path;
    };
  };

  services.nginx.virtualHosts."${vars.services.keycloak.subdomain}.${vars.zone}" = {
    enableACME = true;
    forceSSL = true;
    locations."/".proxyPass = "http://${config.services.keycloak.settings.http-host}:${toString config.services.keycloak.settings.http-port}";
  };

  sops.secrets."backups/restic/keycloak/repositoryPass" = { };
  sops.secrets."backups/restic/keycloak/sshKey" = { };
  services.restic.backups.keycloak = {
    backupPrepareCommand = ''
      ${pkgs.bash}/bin/bash -c '
        if ! mkdir -p "${vars.services.keycloak.backups.tmpDir}"; then
          echo "Could not create backup folder '${vars.services.keycloak.backups.tmpDir}'" >&2
          exit 1
        fi

        ${pkgs.mariadb}/bin/mariabackup --backup --user=root --password=$(cat ${
          config.sops.secrets."services/keycloak/db/password".path
        }) \
           --stream=xbstream | ${pkgs.gzip}/bin/gzip > "${vars.services.keycloak.backups.tmpDir}/keycloak-db-dump.sql.gz"
      '
    '';
    paths = [ vars.services.keycloak.backups.tmpDir ];
    repository = "sftp:${
      vars.sensitive.backups.user + "@" + vars.sensitive.backups.host
    }:restic-repo-keycloak";
    extraOptions = [
      "sftp.command='ssh ${vars.sensitive.backups.user + "@" + vars.sensitive.backups.host} -p 23 -i ${
        config.sops.secrets."backups/restic/keycloak/sshKey".path
      } -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -s sftp'"
    ];
    initialize = true;
    passwordFile = config.sops.secrets."backups/restic/keycloak/repositoryPass".path;
    backupCleanupCommand = ''
      ${pkgs.bash}/bin/bash -c 'rm -rf "${vars.services.keycloak.backups.tmpDir}"'
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
