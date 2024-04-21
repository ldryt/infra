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
      image = "ghcr.io/shlinkio/shlink:4.1@sha256:7a43d41029ea879234359f0a30a59efaa8ede35a3d94e73fbad84845f5927c74";
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
      image = "docker.io/library/postgres:16.2@sha256:f4b0987cb4ba8bcc2b90aa33ad8b5786669bec4dc633fc93d1418275e3627b34";
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
