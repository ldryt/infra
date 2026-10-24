{ config, pkgs, ... }:
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
    serviceConfig.RemainAfterExit = true;
    script = ''
      check=$(${pkgs.podman}/bin/podman network ls | grep "${podmanNetwork}" || true)
      if [ -z "$check" ];
        then ${pkgs.podman}/bin/podman network create ${podmanNetwork}
        else echo "${podmanNetwork} already exists in podman"
      fi
    '';
  };

  systemd.services.podman-shlink-server = {
    requires = [ "init-shlink-network.service" ];
    after = [ "init-shlink-network.service" ];
  };
  systemd.services.podman-shlink-db = {
    requires = [ "init-shlink-network.service" ];
    after = [ "init-shlink-network.service" ];
  };

  sops.secrets."services/shlink/server/env".owner = config.users.users.colon.name;
  sops.secrets."services/shlink/db/env".owner = config.users.users.colon.name;
  virtualisation.oci-containers.containers = {
    "shlink-server" = {
      hostname = "shlink-server";
      # renovate: datasource=docker depName=ghcr.io/shlinkio/shlink
      image = "ghcr.io/shlinkio/shlink:5.1.7@sha256:844e1f2b6455331c5b49207bad3a2455ccd65e62bb9daa09a6c57afff26bd9c8";
      environment = {
        DEFAULT_DOMAIN = config.ldryt-infra.dns.zone;
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
      # renovate: datasource=docker depName=postgres
      image = "docker.io/library/postgres:18.6@sha256:edb0c08dc33befd0262ab3b5cf1c4f3f8cfd8b09e88c05b45adee29d6761ddb6";
      environment = {
        POSTGRES_USER = "postgres";
        POSTGRES_DB = "shlink";
      };
      environmentFiles = [ config.sops.secrets."services/shlink/db/env".path ];
      volumes = [ "shlink-db-data:/var/lib/postgresql/data" ];
      extraOptions = [ "--network=${podmanNetwork}" ];
    };
  };

  services.nginx.virtualHosts."${config.ldryt-infra.dns.zone}" = {
    enableACME = true;
    forceSSL = true;
    locations."= /${subfolder}".proxyPass = "http://127.0.0.1:${internalPort}";
    locations."^~ /${subfolder}/".proxyPass = "http://127.0.0.1:${internalPort}";
  };

  sops.secrets."backups/restic/repos/shlink/password" = { };
  ldryt-infra.backups.repos.shlink = {
    passwordFile = config.sops.secrets."backups/restic/repos/shlink/password".path;
    paths = [ backupsTmpDir ];
    backupPrepareCommand = ''
      ${pkgs.bash}/bin/bash -c '
        set -euo pipefail
        if ! mkdir -p "${backupsTmpDir}"; then
          echo "Could not create backup folder '${backupsTmpDir}'" >&2
          exit 1
        fi

        ${pkgs.podman}/bin/podman exec shlink-db \
          pg_dumpall -c -U ${config.virtualisation.oci-containers.containers.shlink-db.environment.POSTGRES_USER} | \
          ${pkgs.gzip}/bin/gzip > "${backupsTmpDir}/shlink-db-dump.sql.gz"
      '
    '';
    backupCleanupCommand = ''
      ${pkgs.bash}/bin/bash -c 'rm -rf "${backupsTmpDir}"'
    '';
  };
}
