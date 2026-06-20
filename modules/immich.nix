{
  config,
  lib,
  pkgs,
  pkgs-master,
  ...
}:
let
  cfg = config.ldryt-infra.immich;
  host = config.networking.hostName;

  hasRole = r: lib.elem r cfg.nodes.${host}.roles;
  hostWithRole = r: lib.findFirst (h: lib.elem r cfg.nodes.${h}.roles) null (lib.attrNames cfg.nodes);
in
{
  imports = [ ./wireguard-mesh.nix ];

  options.ldryt-infra.immich = {
    enable = lib.mkEnableOption "multi-host immich";

    nodes = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            ip = lib.mkOption { type = lib.types.str; };
            publicKey = lib.mkOption { type = lib.types.str; };
            roles = lib.mkOption {
              type = lib.types.listOf (
                lib.types.enum [
                  "server"
                  "ml"
                ]
              );
            };
          };
        }
      );
      default = {
        silvermist = {
          ip = "10.114.44.1";
          publicKey = "CzUHVmitMA/I/j7p0E0pW2IYtVx7r+ofgUGMC5roEnk=";
          roles = [ "server" ];
        };
        luke = {
          ip = "10.114.44.2";
          publicKey = "+OpKi943ZB5i18dFxBmjV4Eu5t9fv6AcMJyYKq272kA=";
          roles = [ "ml" ];
        };
      };
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs-master.immich;
    };
    mediaLocation = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/immich";
    };
    gdriveArchiveMount = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/gdrive-photos-2004-2017";
    };

    ml = {
      port = lib.mkOption {
        type = lib.types.port;
        default = 3003;
      };
      clipModel = lib.mkOption {
        type = lib.types.str;
        default = "ViT-SO400M-16-SigLIP2-384__webli";
      };
      ocrModel = lib.mkOption {
        type = lib.types.str;
        default = "PP-OCRv5_server";
      };
      facialModel = lib.mkOption {
        type = lib.types.str;
        default = "buffalo_l";
      };
    };

    oidc = {
      clientID = lib.mkOption {
        type = lib.types.str;
        default = "YL~WkjeeJXxVWOs01mdJjXJarT6yssLlf4yZdAowKL61OWpP3G2WbR1D9y2RBAjh_xHSXRGo";
      };
      signingAlg = lib.mkOption {
        type = lib.types.str;
        default = "RS256";
      };
    };
    smtpSender = lib.mkOption {
      type = lib.types.str;
      default = "pics@ldryt.dev";
    };

    mesh = {
      subnet = lib.mkOption {
        type = lib.types.str;
        default = "10.114.44.0/24";
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = 44871;
      };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        sops.secrets."services/immich/wg/privateKey" = { };
        ldryt-infra.wireguard-meshes.immich = {
          interface = "wg-immich";
          inherit (cfg.mesh) subnet port;
          privateKeyFile = config.sops.secrets."services/immich/wg/privateKey".path;
          hub = hostWithRole "server";
          peers = lib.mapAttrs (_: p: { inherit (p) ip publicKey; }) cfg.nodes;
        };
      }

      (lib.mkIf (hasRole "server") {
        ldryt-infra.persist.directories = [
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
            cfg.mediaLocation
            config.services.postgresqlBackup.location
          ];
        };

        ldryt-infra.monitoring.blackbox.targets = {
          http_ok = [
            "https://${config.ldryt-infra.dns.records.immich}/api/server/ping"
            config.services.immich.environment.IMMICH_MACHINE_LEARNING_URL
          ];
          http_protected = [
            "https://${config.ldryt-infra.dns.records.immich}/api/auth/status"
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

        services.immich = {
          enable = true;
          package = cfg.package;
          mediaLocation = cfg.mediaLocation;
          database = {
            enable = true;
            enableVectorChord = true;
            enableVectors = false;
          };
          redis.enable = true;
          machine-learning.enable = false;
          environment = {
            IMMICH_CONFIG_FILE = config.sops.templates."immich.json".path;
            IMMICH_MACHINE_LEARNING_URL = lib.mkForce "http://${
              cfg.nodes.${hostWithRole "ml"}.ip
            }:${toString cfg.ml.port}";
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
                clip.modelName = cfg.ml.clipModel;
                ocr = {
                  modelName = cfg.ml.ocrModel;
                  maxResolution = 1280;
                };
                facialRecognition.modelName = cfg.ml.facialModel;
                availabilityChecks.timeout = 5000;
              };
              newVersionCheck.enabled = false;
              oauth = {
                enabled = true;
                autoRegister = true;
                autoLaunch = true;
                buttonText = "Login with ${config.ldryt-infra.dns.records.authelia}";
                defaultStorageQuota = 5;
                clientId = cfg.oidc.clientID;
                clientSecret = config.sops.placeholder."services/immich/oidc/clientSecret";
                issuerUrl = "https://${config.ldryt-infra.dns.records.authelia}/.well-known/openid-configuration";
                signingAlgorithm = cfg.oidc.signingAlg;
                profileSigningAlgorithm = cfg.oidc.signingAlg;
                scope = "openid email profile immich_scope";
                storageLabelClaim = "preferred_username";
                storageQuotaClaim = "immich_quota";
                roleClaim = "immich_role";
              };
              passwordLogin.enabled = false;
              notifications.smtp = {
                enabled = true;
                from = cfg.smtpSender;
                transport = {
                  host = "${config.ldryt-infra.dns.records.mailserver}";
                  port = 465;
                  username = cfg.smtpSender;
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
        fileSystems."${cfg.mediaLocation}" = {
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
        fileSystems."${cfg.gdriveArchiveMount}" = {
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
      })

      (lib.mkIf (hasRole "ml") {
        ldryt-infra.persist.directories = [
          {
            directory = config.services.immich.machine-learning.environment.MACHINE_LEARNING_CACHE_FOLDER;
            user = "immich";
          }
        ];

        networking.firewall.interfaces."wg-immich".allowedTCPPorts = [ cfg.ml.port ];

        # https://github.com/NixOS/nixpkgs/issues/418799
        users.users.immich = {
          home = config.services.immich.machine-learning.environment.MACHINE_LEARNING_CACHE_FOLDER;
          createHome = true;
        };

        systemd.services.immich-server.enable = false;
        services.immich = {
          enable = true;
          package = cfg.package;
          database.enable = false;
          redis.enable = false;
          machine-learning = {
            enable = true;
            environment = {
              IMMICH_HOST = lib.mkForce cfg.nodes.${host}.ip;
              MACHINE_LEARNING_PRELOAD__CLIP__TEXTUAL = cfg.ml.clipModel;
              MACHINE_LEARNING_PRELOAD__CLIP__VISUAL = cfg.ml.clipModel;
              MACHINE_LEARNING_PRELOAD__FACIAL_RECOGNITION__DETECTION = cfg.ml.facialModel;
              MACHINE_LEARNING_PRELOAD__FACIAL_RECOGNITION__RECOGNITION = cfg.ml.facialModel;
              MACHINE_LEARNING_PRELOAD__OCR__DETECTION = cfg.ml.ocrModel;
              MACHINE_LEARNING_PRELOAD__OCR__RECOGNITION = cfg.ml.ocrModel;
              MACHINE_LEARNING_MODEL_TTL = "-1";
            };
          };
        };
      })
    ]
  );
}
