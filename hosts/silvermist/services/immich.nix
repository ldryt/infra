{
  config,
  lib,
  pkgs-master,
  pkgs,
  ...
}:
let
  dataDir = "/mnt/immich";
  oidcSigningAlg = "RS256";
  oidcClientID = "YL~WkjeeJXxVWOs01mdJjXJarT6yssLlf4yZdAowKL61OWpP3G2WbR1D9y2RBAjh_xHSXRGo";
  smtpSender = "pics@ldryt.dev";
  mlClipModel = "ViT-B-16-SigLIP__webli";
in
{
  environment.persistence.silvermist.directories = [
    config.services.postgresql.dataDir
    config.services.immich.machine-learning.environment.MACHINE_LEARNING_CACHE_FOLDER
  ];

  sops.secrets."backups/restic/repos/immich/password" = { };
  ldryt-infra.backups.repos.immich = {
    passwordFile = config.sops.secrets."backups/restic/repos/immich/password".path;
    paths = [ dataDir ];
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
  };

  services.immich = {
    enable = true;
    package = pkgs-master.immich;
    mediaLocation = dataDir;
    database = {
      enable = true;
      enableVectorChord = true;
      enableVectors = false;
    };
    redis.enable = true;
    machine-learning = {
      enable = true;
      environment = {
        MACHINE_LEARNING_PRELOAD__CLIP__TEXTUAL = mlClipModel;
      };
    };
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
          transcode = "all";
          acceptedAudioCodecs = [ "aac" ];
          acceptedContainers = [ ];
          acceptedVideoCodecs = [ "hevc" ];
          targetAudioCodec = "aac";
          targetResolution = "1080";
          targetVideoCodec = "hevc";
          crf = 30;
          maxBitrate = "0";
          preset = "medium";
          threads = 1;
          twoPass = false;
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
            concurrency = 4;
          };
          videoConversion = {
            concurrency = 4;
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

  sops.secrets."system/smb/glouton/immich-library/credentials" = { };
  environment.systemPackages = [ pkgs.cifs-utils ];
  fileSystems."${dataDir}" = {
    device = "//u391790-sub1.your-storagebox.de/u391790-sub1";
    fsType = "cifs";
    options = [
      "credentials=${config.sops.secrets."system/smb/glouton/immich-library/credentials".path}"

      "uid=${toString config.services.immich.user}"
      "forceuid"
      "gid=${toString config.services.immich.group}"
      "forcegid"
      "file_mode=0770"
      "dir_mode=0770"

      "vers=3.1.1"
      "sec=ntlmsspi"
      "seal"

      "async"
      "noatime"
      "rsize=4194304"
      "wsize=4194304"
      "fsc"

      "noauto"
      "x-systemd.automount"
      "x-systemd.idle-timeout=600s"
      "x-systemd.mount-timeout=15s"
    ];
  };
}
