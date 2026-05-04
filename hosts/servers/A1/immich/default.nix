{
  config,
  lib,
  pkgs,
  pkgs-master,
  ...
}:
let
  common = import ../../common/immich;
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
    {
      directory = "/var/cache/rclone-vfs-1";
      user = "root";
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

  networking.firewall.allowedUDPPorts = [ common.wg.port ];
  networking.firewall.interfaces."${common.wg.int}".allowedTCPPorts = [
    5432
    common.redis.port
  ];
  sops.secrets."services/immich/wg/privateKey" = { };
  networking.wireguard.interfaces."${common.wg.int}" = {
    ips = [ common.wg.A1.ip ];
    listenPort = common.wg.port;
    privateKeyFile = config.sops.secrets."services/immich/wg/privateKey".path;
    peers = [
      {
        publicKey = common.wg.B1.pubKey;
        allowedIPs = [ common.wg.B1.ip ];
        endpoint = "${common.wg.B1.ip}:${common.wg.port}";
        persistentKeepalive = 25;
      }
      {
        publicKey = common.wg.A2.pubKey;
        allowedIPs = [ common.wg.A2.ip ];
        endpoint = "${common.wg.A2.ip}:${common.wg.port}";
        persistentKeepalive = 25;
      }
    ];
  };

  sops.secrets."services/immich/db/password" = { };
  services.postgresql = {
    enableTCPIP = true;
    authentication = lib.mkOverride 10 ''
      local all all trust
      host immich immich "${common.wg.A2.ip}" scram-sha-256
    '';
  };
  systemd.services.postgresql.postStart = lib.mkAfter ''
    $PSQL -tA -c "ALTER USER immich WITH PASSWORD '$(cat ${
      config.sops.secrets."services/immich/db/password".path
    })';"
  '';

  services.redis.servers.immich = {
    bind = lib.mkForce common.wg.A1.ip;
    port = lib.mkForce common.redis.port;
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

  services.immich = {
    enable = true;
    package = pkgs-master.immich;
    mediaLocation = common.dataDir;
    database = {
      enable = true;
      enableVectorChord = true;
      enableVectors = false;
    };
    redis.enable = true;
    machine-learning.enable = false;

    environment = {
      IMMICH_WORKERS_INCLUDE = "api";
      IMMICH_MACHINE_LEARNING_URL = "http://${common.wg.B1.ip}:${common.mlPort}";
      IMMICH_CONFIG_FILE = config.sops.templates."immich.json".path;
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
          thumbnailGeneration = {
            concurrency = 2;
          };
          videoConversion = {
            concurrency = 1;
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
        machineLearning.clip.modelName = common.ml.model;
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
      ];
      content = lib.strings.toJSON settings;
    };
}
