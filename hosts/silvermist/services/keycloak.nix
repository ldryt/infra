{ config, pkgs, ... }:
let
  dns = builtins.fromJSON (builtins.readFile ../dns.json);
  backupsTmpDir = "/tmp/keycloak_backup";
in
{
  sops.secrets."services/keycloak/db/password" = { };

  services.keycloak = {
    enable = true;
    initialAdminPassword = "matchbook-purse3";
    settings = {
      hostname = "${dns.subdomains.keycloak}.${dns.zone}";
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

  services.nginx.virtualHosts."${dns.subdomains.keycloak}.${dns.zone}" = {
    enableACME = true;
    forceSSL = true;
    kTLS = true;
    locations."/" = {
      proxyPass = "http://${config.services.keycloak.settings.http-host}:${toString config.services.keycloak.settings.http-port}";
      extraConfig = ''
        proxy_buffer_size   128k;
        proxy_buffers   4 256k;
        proxy_busy_buffers_size   256k;
      '';
    };
  };

  ldryt-infra.backups.keycloak = {
    paths = [ backupsTmpDir ];
    backupPrepareCommand = ''
      ${pkgs.bash}/bin/bash -c '
        if ! mkdir -p "${backupsTmpDir}"; then
          echo "Could not create backup folder '${backupsTmpDir}'" >&2
          exit 1
        fi

        ${pkgs.mariadb}/bin/mariabackup --backup --user=root --password=$(cat ${
          config.sops.secrets."services/keycloak/db/password".path
        }) \
           --stream=xbstream | ${pkgs.gzip}/bin/gzip > "${backupsTmpDir}/keycloak-db.mbstream.gz"
      '
    '';
    backupCleanupCommand = ''
      ${pkgs.bash}/bin/bash -c 'rm -rf "${backupsTmpDir}"'
    '';
  };
}
