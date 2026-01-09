{ lib, config, ... }:
{
  environment.persistence.silvermist.directories = (
    # TODO: uniquefy final list
    lib.optionals (!config.services.immich.enable) [
      {
        directory = config.services.postgresqlBackup.location;
        user = "postgres";
      }
      {
        directory = config.services.postgresql.dataDir;
        user = "postgres";
      }
    ]
  );
  sops.secrets."backups/restic/repos/umami/password" = { };
  ldryt-infra.backups.repos.umami = {
    passwordFile = config.sops.secrets."backups/restic/repos/umami/password".path;
    paths = [
      config.services.postgresqlBackup.location
    ];
  };
  services.postgresqlBackup = {
    enable = true;
    databases = [ "umami" ];
  };
  sops.secrets."services/umami/appSecret" = { };
  services.umami = {
    enable = true;
    settings = {
      APP_SECRET_FILE = config.sops.secrets."services/umami/appSecret".path;
      COLLECT_API_ENDPOINT = "/api/sweet";
      TRACKER_SCRIPT_NAME = [ "sweet.js" ];
      DISABLE_TELEMETRY = true;
      DISABLE_UPDATES = true;
    };
  };
  services.nginx.virtualHosts."${config.ldryt-infra.dns.records.umami}" = {
    enableACME = true;
    forceSSL = true;
    kTLS = true;
    locations."/" = {
      proxyWebsockets = true;
      proxyPass = "http://${config.services.umami.settings.HOSTNAME}:${toString config.services.umami.settings.PORT}";
    };
  };
}
