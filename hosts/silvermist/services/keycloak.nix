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

  silvermist.backups.keycloak = {
    paths = [ vars.services.keycloak.backups.tmpDir ];
    backupPrepareCommand = ''
      ${pkgs.bash}/bin/bash -c '
        if ! mkdir -p "${vars.services.keycloak.backups.tmpDir}"; then
          echo "Could not create backup folder '${vars.services.keycloak.backups.tmpDir}'" >&2
          exit 1
        fi

        ${pkgs.mariadb}/bin/mariabackup --backup --user=root --password=$(cat ${
          config.sops.secrets."services/keycloak/db/password".path
        }) \
           --stream=xbstream | ${pkgs.gzip}/bin/gzip > "${vars.services.keycloak.backups.tmpDir}/keycloak-db.mbstream.gz"
      '
    '';
    backupCleanupCommand = ''
      ${pkgs.bash}/bin/bash -c 'rm -rf "${vars.services.keycloak.backups.tmpDir}"'
    '';
  };
}
