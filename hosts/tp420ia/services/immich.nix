{
  config,
  lib,
  pkgs-master,
  ...
}:
let
  immichMediaDir = "/mnt/immich";
  oidcSigningAlg = "RS256";
  oidcClientID = "YL~WkjeeJXxVWOs01mdJjXJarT6yssLlf4yZdAowKL61OWpP3G2WbR1D9y2RBAjh_xHSXRGo";
  smtpSender = "pics@ldryt.dev";
  mlClipModel = "ViT-SO400M-16-SigLIP2-384__webli";
in
{
  environment.persistence.tp420ia.directories = [
    config.services.postgresql.dataDir
    config.services.immich.machine-learning.environment.MACHINE_LEARNING_CACHE_FOLDER
  ];

  fileSystems."${immichMediaDir}" = {
    device = "/dev/mapper/2a37-data";
    fsType = "btrfs";
    options = [
      "defaults"
      "nofail"
      "subvol=immich"
    ];
  };

  sops.secrets."backups/restic/repos/immich/password" = { };
  ldryt-infra.backups.repos.immich = {
    passwordFile = config.sops.secrets."backups/restic/repos/immich/password".path;
    paths = [ immichMediaDir ];
  };

  services.nginx.virtualHosts."${config.ldryt-infra.dns.records.immich}" = {
    enableACME = true;
    forceSSL = true;
    kTLS = true;
    locations."/" = {
      proxyWebsockets = true;
      proxyPass = "http://${config.services.immich.host}:${toString config.services.immich.port}";
      extraConfig = ''
        client_max_body_size 0;
      '';
    };
  };

  # https://github.com/NixOS/nixpkgs/issues/418799
  users.users.immich = {
    home = config.services.immich.machine-learning.environment.MACHINE_LEARNING_CACHE_FOLDER;
    createHome = true;

    # Allow access to /dev/dri/renderD128
    extraGroups = [ "render" ];
  };

  services.immich = {
    enable = true;
    package = pkgs-master.immich;
    mediaLocation = immichMediaDir;
    database.enable = true;
    redis.enable = true;
    machine-learning = {
      enable = true;
      environment = {
        MACHINE_LEARNING_PRELOAD__CLIP__TEXTUAL = mlClipModel;
      };
    };
    accelerationDevices = [ "/dev/dri/renderD128" ];
    environment.IMMICH_CONFIG_FILE = config.sops.templates."immich.json".path;
  };

  # https://github.com/NixOS/nixpkgs/issues/369379#issuecomment-3082247079
  sops.secrets."services/immich/oidc/clientSecret".owner = config.services.immich.user;
  sops.secrets."services/immich/mail/clearPassword".owner = config.services.immich.user;
  sops.templates."immich.json" =
    let
      settings = {
        server.externalDomain = "https://${config.ldryt-infra.dns.records.immich}";
        backup.database = {
          enabled = true;
          cronExpression = "0 */6 * * *";
          keepLastAmount = 60;
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
          crf = 32;
          maxBitrate = "0";
          preset = "veryslow";
          threads = 1;
          twoPass = false;
          # mobius would mess with ffmpeg options and VAAPI
          tonemap = "hable";
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
            quality = 85;
          };
          preview = {
            format = "webp";
            quality = 80;
            size = 1440;
          };
          thumbnail = {
            format = "webp";
            quality = 80;
            size = 250;
          };
        };
        job = {
          thumbnailGeneration = {
            concurrency = 6;
          };
          videoConversion = {
            concurrency = 6;
          };
          smartSearch = {
            concurrency = 1;
          };
          faceDetection = {
            concurrency = 1;
          };
        };
        logging = {
          enabled = true;
          level = "debug";
        };
        machineLearning.clip.modelName = mlClipModel;
        newVersionCheck.enabled = false;
        oauth = {
          enabled = true;
          autoRegister = true;
          autoLaunch = true;
          buttonText = "Login with ${config.ldryt-infra.dns.records.authelia}";
          defaultStorageQuota = 5;
          clientId = oidcClientID;
          clientSecret = config.sops.placeholder."services/immich/oidc/clientSecret";
          issuerUrl = "https://${config.ldryt-infra.dns.records.authelia}/.well-known/openid-configuration";
          signingAlgorithm = oidcSigningAlg;
          profileSigningAlgorithm = oidcSigningAlg;
          scope = "openid email profile immich_scope";
          storageLabelClaim = "preferred_username";
          storageQuotaClaim = "immich_quota";
          roleClaim = "immich_role";
        };
        passwordLogin.enabled = false;
        notifications.smtp = {
          enabled = true;
          from = smtpSender;
          transport = {
            host = "${config.ldryt-infra.dns.records.mailserver}";
            port = 465;
            username = smtpSender;
            password = config.sops.placeholder."services/immich/mail/clearPassword";
          };
        };
      };
    in
    {
      owner = config.services.immich.user;
      restartUnits = [
        "immich-server.service"
        "immich-machine-learning.service"
      ];
      content = lib.strings.toJSON settings;
    };
}
