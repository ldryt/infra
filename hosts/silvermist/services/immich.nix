{
  config,
  lib,
  pkgs,
  pkgs-master,
  ...
}:
let
  common = import ../../common/immich { inherit pkgs-master; };
in
{
  environment.persistence.silvermist.directories = [
    {
      directory = config.services.postgresqlBackup.location;
      user = "postgres";
    }
    {
      directory = config.services.postgresql.dataDir;
      user = "postgres";
    }
  ];

  sops.secrets."backups/restic/repos/immich/password" = { };
  ldryt-infra.backups.repos.immich = {
    passwordFile = config.sops.secrets."backups/restic/repos/immich/password".path;
    paths = [
      common.dataDir
      config.services.postgresqlBackup.location
    ];
  };

  services.postgresqlBackup = {
    enable = true;
    databases = [ "immich" ];
  };

  services.nginx.virtualHosts."${config.ldryt-infra.dns.records.immich}" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyWebsockets = true;
      proxyPass = "http://${config.services.immich.host}:${toString config.services.immich.port}";
      extraConfig = ''
        client_max_body_size 0;
      '';
    };
  };

  networking.firewall.allowedUDPPorts = [ common.wg.port ];
  sops.secrets."services/immich/wg/privateKey" = { };
  networking.wireguard.interfaces."${common.wg.int}" = {
    ips = [ "${common.wg.silvermist.ip}${common.wg.subnet}" ];
    listenPort = common.wg.port;
    privateKeyFile = config.sops.secrets."services/immich/wg/privateKey".path;
    peers = [
      {
        publicKey = common.wg.luke.pubKey;
        allowedIPs = [ "${common.wg.luke.ip}/32" ];
        endpoint = "luke.${config.ldryt-infra.dns.zone}:${toString common.wg.port}";
        persistentKeepalive = 25;
      }
    ];
  };

  services.immich = {
    enable = true;
    package = common.immichPkg;
    mediaLocation = common.dataDir;
    database = {
      enable = true;
      enableVectorChord = true;
      enableVectors = false;
    };
    redis.enable = true;
    machine-learning.enable = false;
    environment = {
      IMMICH_CONFIG_FILE = config.sops.templates."immich.json".path;
      IMMICH_MACHINE_LEARNING_URL = lib.mkForce "http://${common.wg.luke.ip}:${toString common.ml.port}";
    };
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
          videoConversion.concurrency = 2;
          smartSearch.concurrency = 2;
          faceDetection.concurrency = 2;
          ocr.concurrency = 2;
        };
        logging = {
          enabled = true;
          level = "debug";
        };
        machineLearning = {
          clip.modelName = common.ml.clipModel;
          ocr = {
            modelName = common.ml.ocrModel;
            maxResolution = 1280;
          };
          facialRecognition.modelName = common.ml.facialModel;
          availabilityChecks.timeout = 5000;
        };
        newVersionCheck.enabled = false;
        oauth = {
          enabled = true;
          autoRegister = true;
          autoLaunch = true;
          buttonText = "Login with ${config.ldryt-infra.dns.records.authelia}";
          defaultStorageQuota = 5;
          clientId = common.oidc.clientID;
          clientSecret = config.sops.placeholder."services/immich/oidc/clientSecret";
          issuerUrl = "https://${config.ldryt-infra.dns.records.authelia}/.well-known/openid-configuration";
          signingAlgorithm = common.oidc.signingAlg;
          profileSigningAlgorithm = common.oidc.signingAlg;
          scope = "openid email profile immich_scope";
          storageLabelClaim = "preferred_username";
          storageQuotaClaim = "immich_quota";
          roleClaim = "immich_role";
        };
        passwordLogin.enabled = false;
        notifications.smtp = {
          enabled = true;
          from = common.smtpSender;
          transport = {
            host = "${config.ldryt-infra.dns.records.mailserver}";
            port = 465;
            username = common.smtpSender;
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

  environment.systemPackages = [
    pkgs.cifs-utils
    pkgs.rclone
  ];

  sops.secrets."system/smb/glouton/immich-library/credentials" = { };
  fileSystems."${common.dataDir}" = {
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

  sops.secrets."system/rclone/gdrive-photos-2004-2017-crypted/rclone.conf" = { };
  fileSystems."${common.gdriveArchiveMount}" = {
    device = "gdrive-photos-2004-2017-crypted:/";
    fsType = "rclone";
    options = [
      "nodev"
      "nofail"

      "allow_other"
      "default_permissions"
      "uid=${toString config.services.immich.user}"
      "gid=${toString config.services.immich.group}"
      "umask=007"

      "cache-dir=/var/cache/rclone-vfs-1"
      "vfs-cache-mode=full"
      "vfs-cache-min-free-space=5G"
      "vfs-cache-max-age=6w"

      "log-level=DEBUG"

      "args2env"
      "config=${config.sops.secrets."system/rclone/gdrive-photos-2004-2017-crypted/rclone.conf".path}"
    ];
  };
}
