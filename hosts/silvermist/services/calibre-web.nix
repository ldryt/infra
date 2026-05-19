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
  };
}
