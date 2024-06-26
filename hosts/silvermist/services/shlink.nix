{
  config,
  pkgs,
  dns,
  ...
}:
let
  subfolder = "link";
  podmanNetwork = "shlink-network";
  internalPort = "44086";
  backupsTmpDir = "/tmp/shlink_backup";
in
{
  systemd.services.init-shlink-network = {
    description = "Create the network named ${podmanNetwork}.";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      check=$(${pkgs.podman}/bin/podman network ls | grep "${podmanNetwork}" || true)
      if [ -z "$check" ];
        then ${pkgs.podman}/bin/podman network create ${podmanNetwork}
        else echo "${podmanNetwork} already exists in podman"
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
        DEFAULT_DOMAIN = dns.silvermist.zone;
        IS_HTTPS_ENABLED = "true";
        BASE_PATH = "/${subfolder}";
        DB_DRIVER = "postgres";
        DB_HOST = "shlink-db";
        DB_NAME = config.virtualisation.oci-containers.containers.shlink-db.environment.POSTGRES_DB;
        DB_USER = config.virtualisation.oci-containers.containers.shlink-db.environment.POSTGRES_USER;
      };
      environmentFiles = [
        config.sops.secrets."services/shlink/server/env".path
        config.sops.secrets."services/shlink/db/env".path
      ];
      ports = [ "127.0.0.1:${internalPort}:8080" ];
      dependsOn = [ "shlink-db" ];
      extraOptions = [ "--network=${podmanNetwork}" ];
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
      extraOptions = [ "--network=${podmanNetwork}" ];
    };
  };

  services.nginx.virtualHosts."${dns.silvermist.zone}" = {
    enableACME = true;
    forceSSL = true;
    kTLS = true;
    locations."/${subfolder}".proxyPass = "http://127.0.0.1:${internalPort}";
  };

  ldryt-infra.backups.shlink = {
    paths = [ backupsTmpDir ];
    backupPrepareCommand = ''
      ${pkgs.bash}/bin/bash -c '
        if ! mkdir -p "${backupsTmpDir}"; then
          echo "Could not create backup folder '${backupsTmpDir}'" >&2
          exit 1
        fi

        ${pkgs.podman}/bin/podman exec -t shlink-db \
          pg_dumpall -c -U ${config.virtualisation.oci-containers.containers.shlink-db.environment.POSTGRES_USER} | \
          ${pkgs.gzip}/bin/gzip > "${backupsTmpDir}/shlink-db-dump.sql.gz"
      '
    '';
    backupCleanupCommand = ''
      ${pkgs.bash}/bin/bash -c 'rm -rf "${backupsTmpDir}"'
    '';
  };
}
