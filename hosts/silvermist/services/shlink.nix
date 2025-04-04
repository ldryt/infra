{ config, pkgs, ... }:
let
  dns = builtins.fromJSON (builtins.readFile ../dns.json);
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
      image = "ghcr.io/shlinkio/shlink:4.4.6";
      environment = {
        DEFAULT_DOMAIN = dns.zone;
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
      image = "docker.io/library/postgres:16.2";
      environment = {
        POSTGRES_USER = "postgres";
        POSTGRES_DB = "shlink";
      };
      environmentFiles = [ config.sops.secrets."services/shlink/db/env".path ];
      volumes = [ "shlink-db-data:/var/lib/postgresql/data" ];
      extraOptions = [ "--network=${podmanNetwork}" ];
    };
  };

  services.nginx.virtualHosts."${dns.zone}" = {
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
