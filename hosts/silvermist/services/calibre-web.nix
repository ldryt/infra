{ config, pkgs, ... }:
let
  port = 8083;
  dataDir = "/var/lib/calibre-web";
  libraryDir = "/var/lib/calibre-library";
in
{
  environment.persistence.silvermist.directories = [
    {
      directory = dataDir;
      user = config.services.calibre-web.user;
    }
    {
      directory = libraryDir;
      user = config.services.calibre-web.user;
    }
  ];

  services.calibre-web = {
    enable = true;
    listen = {
      ip = "127.0.0.1";
      inherit port;
    };
    options = {
      calibreLibrary = libraryDir;
      enableBookUploading = true;
      enableBookConversion = true;
    };
  };

  services.nginx.virtualHosts."${config.ldryt-infra.dns.records.calibre-web}" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString port}";
      proxyWebsockets = true;
      extraConfig = ''
        client_max_body_size 500M;
      '';
    };
  };

  ldryt-infra.monitoring.blackbox.targets = {
    http_ok = [
      "http://${config.ldryt-infra.dns.records.calibre-web}/"
    ];
  };

  sops.secrets."backups/restic/repos/calibre-web/password" = { };
  ldryt-infra.backups.repos.calibre-web = {
    passwordFile = config.sops.secrets."backups/restic/repos/calibre-web/password".path;
    paths = [
      dataDir
      libraryDir
    ];

    backupPrepareCommand = ''
      ${pkgs.bash}/bin/bash -c '
        if [[ -f "${dataDir}/app.db" ]]; then
          ${pkgs.sqlite}/bin/sqlite3 "${dataDir}/app.db" ".backup '${dataDir}/app.db.bak'"
        fi
        if [[ -f "${libraryDir}/metadata.db" ]]; then
          ${pkgs.sqlite}/bin/sqlite3 "${libraryDir}/metadata.db" ".backup '${libraryDir}/metadata.db.bak'"
        fi
      '
    '';
    backupCleanupCommand = ''
      ${pkgs.bash}/bin/bash -c '
        rm -f "${dataDir}/app.db.bak"
        rm -f "${libraryDir}/metadata.db.bak"
      '
    '';
  };
}
