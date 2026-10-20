{
  config,
  pkgs,
  pkgs-master,
  ...
}:
let
  cfg = config.services.immich;
  archive = "/mnt/photos-2004-2017";
in
{
  sops.secrets = {
    "services/immich/oidc/clientSecret".restartUnits = [ "immich-server.service" ];
    "services/immich/mail/clearPassword".restartUnits = [ "immich-server.service" ];
    "backups/restic/repos/immich/password" = { };
  };

  fileSystems.${cfg.mediaLocation} = {
    device = "/dev/mapper/2a37-data";
    fsType = "btrfs";
    options = [
      "subvol=domus-immich"
      "noatime"
      "nofail"
      "x-systemd.device-timeout=30s"
    ];
  };

  ldryt-infra.rclone.mounts.photos-2004-2017 = {
    mountPoint = archive;
    group = "immich-archive";
    umask = "0027";
    readOnly = true;
  };

  ldryt-infra.persist.directories = [
    {
      directory = config.services.postgresql.dataDir;
      user = "postgres";
      group = "postgres";
    }
    {
      directory = config.services.postgresqlBackup.location;
      user = "postgres";
      group = "postgres";
    }
    {
      directory = "/var/lib/immich";
      user = cfg.user;
      group = cfg.group;
    }
    {
      directory = cfg.machine-learning.environment.MACHINE_LEARNING_CACHE_FOLDER;
      user = cfg.user;
      group = cfg.group;
    }
    {
      directory = config.services.redis.servers.immich.settings.dir;
      user = config.services.redis.servers.immich.user;
      group = config.services.redis.servers.immich.group;
    }
  ];

  ldryt-infra.backups.repos.immich = {
    passwordFile = config.sops.secrets."backups/restic/repos/immich/password".path;
    paths = [
      cfg.mediaLocation
      config.services.postgresqlBackup.location
    ];
    backupPrepareCommand = "${pkgs.systemd}/bin/systemctl start postgresqlBackup-immich.service";
  };

  systemd.services.immich-server.unitConfig.RequiresMountsFor = [
    cfg.mediaLocation
    archive
  ];

  systemd.services."restic-backups-immich@glouton".unitConfig.RequiresMountsFor = [
    cfg.mediaLocation
  ];
  systemd.services."restic-backups-immich@onedrive".unitConfig.RequiresMountsFor = [
    cfg.mediaLocation
  ];

  services.postgresql.package = pkgs.postgresql_14;
  services.postgresqlBackup = {
    enable = true;
    databases = [ "immich" ];
  };

  users.users.immich = {
    home = cfg.machine-learning.environment.MACHINE_LEARNING_CACHE_FOLDER;
    createHome = true;
    extraGroups = [
      "render"
      "immich-archive"
    ];
  };
  users.groups.immich-archive.gid = 1445;

  hardware.graphics.enable = true;

  services.immich = {
    enable = true;
    package = pkgs-master.immich;
    mediaLocation = "/mnt/immich";
    accelerationDevices = [ "/dev/dri/renderD128" ];
    settings = {
      server.externalDomain = "https://${config.ldryt-infra.dns.records.immich}";
      backup.database = {
        enabled = true;
        cronExpression = "0 */6 * * *";
        keepLastAmount = 8;
      };
      ffmpeg = {
        accel = "vaapi";
        accelDecode = true;
        transcode = "all";
        acceptedAudioCodecs = [ "aac" ];
        acceptedContainers = [ ];
        acceptedVideoCodecs = [ "hevc" ];
        targetAudioCodec = "aac";
        targetResolution = "1080";
        targetVideoCodec = "hevc";
        crf = 30;
        preset = "medium";
      };
      storageTemplate = {
        enabled = true;
        hashVerificationEnabled = true;
        template = "{{#if album}}{{album}}{{else}}{{y}}/{{WW}}{{/if}}/{{HH}}/{{filetype}}_{{y}}{{MM}}{{dd}}-{{HH}}{{mm}}{{ss}}{{SSS}}_{{assetId}}";
      };
      image = {
        fullsize = {
          enabled = true;
          format = "webp";
          quality = 90;
        };
        preview = {
          format = "jpeg";
          progressive = true;
          quality = 80;
          size = 1080;
        };
        thumbnail = {
          format = "webp";
          quality = 70;
          size = 250;
        };
      };
      job = {
        thumbnailGeneration.concurrency = 4;
        videoConversion.concurrency = 1;
        smartSearch.concurrency = 1;
        faceDetection.concurrency = 1;
        ocr.concurrency = 1;
      };
      machineLearning = {
        clip.modelName = "ViT-B-16-SigLIP2__webli";
        ocr = {
          modelName = "PP-OCRv5_mobile";
          maxResolution = 1280;
        };
        facialRecognition.modelName = "buffalo_l";
        availabilityChecks.timeout = 30000;
      };
      oauth = {
        enabled = true;
        autoRegister = true;
        autoLaunch = true;
        buttonText = "Login with ${config.ldryt-infra.dns.records.authelia}";
        defaultStorageQuota = 5;
        clientId = "YL~WkjeeJXxVWOs01mdJjXJarT6yssLlf4yZdAowKL61OWpP3G2WbR1D9y2RBAjh_xHSXRGo";
        clientSecret._secret = config.sops.secrets."services/immich/oidc/clientSecret".path;
        issuerUrl = "https://${config.ldryt-infra.dns.records.authelia}/.well-known/openid-configuration";
        signingAlgorithm = "RS256";
        profileSigningAlgorithm = "RS256";
        scope = "openid email profile immich_scope";
        storageLabelClaim = "preferred_username";
        storageQuotaClaim = "immich_quota";
        roleClaim = "immich_role";
      };
      passwordLogin.enabled = false;
      notifications.smtp = {
        enabled = true;
        from = "pics@ldryt.dev";
        transport = {
          host = config.ldryt-infra.dns.records.mailserver;
          port = 465;
          username = "pics@ldryt.dev";
          password._secret = config.sops.secrets."services/immich/mail/clearPassword".path;
        };
      };
    };
  };

  services.nginx.virtualHosts.${config.ldryt-infra.dns.records.immich} = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://${cfg.host}:${toString cfg.port}";
      proxyWebsockets = true;
      extraConfig = "client_max_body_size 0;";
    };
  };

  ldryt-infra.monitoring.blackbox.targets = {
    http_ok = [ "https://${config.ldryt-infra.dns.records.immich}/api/server/ping" ];
    http_protected = [ "https://${config.ldryt-infra.dns.records.immich}/api/auth/status" ];
  };
}
