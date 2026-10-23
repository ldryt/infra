{
  config,
  pkgs,
  ...
}:
{
  ldryt-infra.persist.directories = [
    {
      directory = config.services.postgresqlBackup.location;
      user = "postgres";
      group = "postgres";
    }
    {
      directory = config.services.postgresql.dataDir;
      user = "postgres";
      group = "postgres";
    }
  ];
  sops.secrets."backups/restic/repos/umami/password" = { };
  ldryt-infra.backups.repos.umami = {
    passwordFile = config.sops.secrets."backups/restic/repos/umami/password".path;
    paths = [
      "${config.services.postgresqlBackup.location}/umami.sql.gz"
    ];
    backupPrepareCommand = "${pkgs.systemd}/bin/systemctl start postgresqlBackup-umami.service";
  };
  services.postgresqlBackup = {
    enable = true;
    databases = [ "umami" ];
  };
  sops.secrets."services/umami/appSecret" = { };
  services.umami = {
    enable = true;
    package = pkgs.umami.overrideAttrs (old: {
      checkPhase =
        builtins.replaceStrings [ "pnpm test" ] [ "pnpm test --testTimeout=30000" ]
          old.checkPhase;
    });
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
    locations."/" = {
      proxyWebsockets = true;
      proxyPass = "http://${config.services.umami.settings.HOSTNAME}:${toString config.services.umami.settings.PORT}";
    };
  };
}
