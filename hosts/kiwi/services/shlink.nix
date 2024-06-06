{
  config,
  pkgs,
  vars,
  ...
}:
{
  systemd.services.init-shlink-network = {
    description = "Create the network named ${vars.services.shlink.podmanNetwork}.";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      check=$(${pkgs.podman}/bin/podman network ls | grep "${vars.services.shlink.podmanNetwork}" || true)
      if [ -z "$check" ];
        then ${pkgs.podman}/bin/podman network create ${vars.services.shlink.podmanNetwork}
        else echo "${vars.services.shlink.podmanNetwork} already exists in podman"
      fi
    '';
  };

  sops.secrets."services/shlink/server/env".owner = config.users.users.colon.name;
  sops.secrets."services/shlink/db/env".owner = config.users.users.colon.name;
  virtualisation.oci-containers.containers = {
    "shlink-server" = {
      hostname = "shlink-server";
      image = "ghcr.io/shlinkio/shlink:4.1.1@sha256:b8b6cce3f3ec840f8b8acbfb96b1fea0546f0780f3ebd326d60d3f92bb10c7e6"; # https://github.com/shlinkio/shlink/pkgs/container/shlink/219894946?tag=4.1.1
      environment = {
        DEFAULT_DOMAIN = vars.zone;
        IS_HTTPS_ENABLED = "true";
        BASE_PATH = "/${vars.services.shlink.subfolder}";
        DB_DRIVER = "postgres";
        DB_HOST = "shlink-db";
        DB_NAME = config.virtualisation.oci-containers.containers.shlink-db.environment.POSTGRES_DB;
        DB_USER = config.virtualisation.oci-containers.containers.shlink-db.environment.POSTGRES_USER;
      };
      environmentFiles = [
        config.sops.secrets."services/shlink/server/env".path
        config.sops.secrets."services/shlink/db/env".path
      ];
      ports = [ "127.0.0.1:${vars.services.shlink.internalPort}:8080" ];
      dependsOn = [ "shlink-db" ];
      extraOptions = [ "--network=${vars.services.shlink.podmanNetwork}" ];
    };
    "shlink-db" = {
      hostname = "shlink-db";
      image = "docker.io/library/postgres:16.2@sha256:07572430dbcd821f9f978899c3ab3a727f5029be9298a41662e1b5404d5b73e0"; # https://hub.docker.com/layers/library/postgres/16.2/images/sha256-07572430dbcd821f9f978899c3ab3a727f5029be9298a41662e1b5404d5b73e0?context=explore
      environment = {
        POSTGRES_USER = "postgres";
        POSTGRES_DB = "shlink";
      };
      environmentFiles = [ config.sops.secrets."services/shlink/db/env".path ];
      volumes = [ "shlink-db-data:/var/lib/postgresql/data" ];
      extraOptions = [ "--network=${vars.services.shlink.podmanNetwork}" ];
    };
  };

  services.nginx.virtualHosts."${vars.zone}" = {
    enableACME = true;
    forceSSL = true;
    kTLS = true;
    locations."/${vars.services.shlink.subfolder}".proxyPass = "http://127.0.0.1:${vars.services.shlink.internalPort}";
  };

  kiwi.backups.shlink = {
    paths = [ vars.services.shlink.backups.tmpDir ];
    backupPrepareCommand = ''
      ${pkgs.bash}/bin/bash -c '
        if ! mkdir -p "${vars.services.shlink.backups.tmpDir}"; then
          echo "Could not create backup folder '${vars.services.shlink.backups.tmpDir}'" >&2
          exit 1
        fi

        ${pkgs.podman}/bin/podman exec -t shlink-db \
          pg_dumpall -c -U ${config.virtualisation.oci-containers.containers.shlink-db.environment.POSTGRES_USER} | \
          ${pkgs.gzip}/bin/gzip > "${vars.services.shlink.backups.tmpDir}/shlink-db-dump.sql.gz"
      '
    '';
    backupCleanupCommand = ''
      ${pkgs.bash}/bin/bash -c 'rm -rf "${vars.services.shlink.backups.tmpDir}"'
    '';
  };
}
