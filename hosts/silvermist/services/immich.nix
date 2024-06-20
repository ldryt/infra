{
  config,
  pkgs,
  vars,
  ...
}:
{
  systemd.services.init-immich-network = {
    description = "Create the network named ${vars.services.immich.podmanNetwork}.";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      check=$(${pkgs.podman}/bin/podman network ls | grep "${vars.services.immich.podmanNetwork}" || true)
      if [ -z "$check" ];
        then ${pkgs.podman}/bin/podman network create ${vars.services.immich.podmanNetwork}
        else echo "${vars.services.immich.podmanNetwork} already exists in podman"
      fi
    '';
  };

  sops.secrets."services/immich/credentials".owner = config.users.users.colon.name;
  virtualisation.oci-containers.containers = {
    "immich-server" = {
      hostname = "immich-server";
      image = "ghcr.io/immich-app/immich-server:v1.106.4@sha256:ad971367766f6b5386fbb80637073aa558eb1cd0a4a3e412c5d5c6457e0df0d5"; # https://github.com/immich-app/immich/pkgs/container/immich-server/229694705?tag=v1.106.4
      environment = {
        IMMICH_CONFIG_FILE = "/etc/immich-config.json";
        DB_HOSTNAME = "immich-db";
        DB_USERNAME = config.virtualisation.oci-containers.containers.immich-db.environment.POSTGRES_USER;
        DB_DATABASE_NAME =
          config.virtualisation.oci-containers.containers.immich-db.environment.POSTGRES_DB;
        DB_PASSWORD = "\${DB_PASSWORD:?error message}";
        REDIS_HOSTNAME = "immich-redis";
      };
      environmentFiles = [ "${config.sops.secrets."services/immich/credentials".path}" ];
      volumes = [
        "/etc/immich/config.json:/etc/immich-config.json:ro"
        "${vars.services.immich.dataDir}:/usr/src/app/upload"
        "/etc/localtime:/etc/localtime:ro"
      ];
      ports = [ "127.0.0.1:${vars.services.immich.internalPort}:3001" ];
      dependsOn = [
        "immich-redis"
        "immich-db"
      ];
      extraOptions = [ "--network=${vars.services.immich.podmanNetwork}" ];
    };
    "immich-machine-learning" = {
      hostname = "immich-machine-learning";
      image = "ghcr.io/immich-app/immich-machine-learning:v1.106.4@sha256:1dcebde9a0c02c7f90ea93f64f883423f8067eef297ff2330d65001e32ce12fd"; # https://github.com/immich-app/immich/pkgs/container/immich-machine-learning/229687734?tag=v1.106.4
      volumes = [ "immich-ml-cache:/cache" ];
      extraOptions = [ "--network=${vars.services.immich.podmanNetwork}" ];
    };
    "immich-db" = {
      hostname = "immich-db";
      image = "docker.io/tensorchord/pgvecto-rs:pg14-v0.2.0@sha256:90724186f0a3517cf6914295b5ab410db9ce23190a2d9d0b9dd6463e3fa298f0";
      environment = {
        POSTGRES_PASSWORD = "\${DB_PASSWORD:?error message}";
        POSTGRES_USER = "postgres";
        POSTGRES_DB = "immich";
      };
      volumes = [ "immich-db-data:/var/lib/postgresql/data" ];
      environmentFiles = config.virtualisation.oci-containers.containers.immich-server.environmentFiles;
      extraOptions = [ "--network=${vars.services.immich.podmanNetwork}" ];
    };
    "immich-redis" = {
      hostname = "immich-redis";
      image = "docker.io/library/redis:6.2-alpine@sha256:84882e87b54734154586e5f8abd4dce69fe7311315e2fc6d67c29614c8de2672";
      extraOptions = [ "--network=${vars.services.immich.podmanNetwork}" ];
    };
  };

  sops.secrets."system/smb/glouton/immich-library/credentials" = { };
  environment.systemPackages = [ pkgs.cifs-utils ];
  fileSystems."${vars.services.immich.dataDir}" = {
    device = vars.sensitive.services.immich.smbShare;
    fsType = "cifs";
    options = [
      "async,rw,auto,nofail,credentials=${
        config.sops.secrets."system/smb/glouton/immich-library/credentials".path
      },uid=${toString config.users.users.colon.uid},cache=loose,fsc"
    ];
  };

  services.nginx.virtualHosts."${vars.services.immich.subdomain}.${vars.zone}" = {
    enableACME = true;
    forceSSL = true;
    kTLS = true;
    locations."/" = {
      proxyWebsockets = true;
      proxyPass = "http://127.0.0.1:${vars.services.immich.internalPort}";
      extraConfig = ''
        client_max_body_size 0;
      '';
    };
  };

  ldryt-infra.backups.immich = {
    paths = [
      vars.services.immich.backups.tmpDir
      vars.services.immich.dataDir
    ];
    backupPrepareCommand = ''
      ${pkgs.bash}/bin/bash -c '
        if ! mkdir -p "${vars.services.immich.backups.tmpDir}"; then
          echo "Could not create backup folder '${vars.services.immich.backups.tmpDir}'" >&2
          exit 1
        fi

        ${pkgs.podman}/bin/podman exec -t immich-db pg_dumpall -c -U postgres | ${pkgs.gzip}/bin/gzip > "${vars.services.immich.backups.tmpDir}/immich-db-dump.sql.gz"
      '
    '';
    backupCleanupCommand = ''
      ${pkgs.bash}/bin/bash -c 'rm -rf "${vars.services.immich.backups.tmpDir}"'
    '';
  };

  environment.etc."immich/config.json".text = ''
    {
      "ffmpeg": {
        "crf": 30,
        "threads": 0,
        "preset": "medium",
        "targetVideoCodec": "vp9",
        "acceptedVideoCodecs": [
          "vp9"
        ],
        "targetAudioCodec": "aac",
        "acceptedAudioCodecs": [
          "aac"
        ],
        "targetResolution": "720",
        "maxBitrate": "0",
        "bframes": -1,
        "refs": 0,
        "gopSize": 0,
        "npl": 0,
        "temporalAQ": false,
        "cqMode": "auto",
        "twoPass": true,
        "preferredHwDevice": "auto",
        "transcode": "all",
        "tonemap": "reinhard",
        "accel": "disabled"
      },
      "job": {
        "backgroundTask": {
          "concurrency": 5
        },
        "smartSearch": {
          "concurrency": 2
        },
        "metadataExtraction": {
          "concurrency": 5
        },
        "faceDetection": {
          "concurrency": 2
        },
        "search": {
          "concurrency": 5
        },
        "sidecar": {
          "concurrency": 5
        },
        "library": {
          "concurrency": 5
        },
        "migration": {
          "concurrency": 5
        },
        "thumbnailGeneration": {
          "concurrency": 5
        },
        "videoConversion": {
          "concurrency": 2
        },
        "notifications": {
          "concurrency": 5
        }
      },
      "logging": {
        "enabled": true,
        "level": "log"
      },
      "machineLearning": {
        "enabled": true,
        "url": "http://immich-machine-learning:3003",
        "clip": {
          "enabled": true,
          "modelName": "immich-app/ViT-B-32__openai"
        },
        "duplicateDetection": {
          "enabled": true,
          "maxDistance": 0.03
        },
        "facialRecognition": {
          "enabled": true,
          "modelName": "buffalo_l",
          "minScore": 0.7,
          "maxDistance": 0.5,
          "minFaces": 3
        }
      },
      "map": {
        "enabled": true,
        "lightStyle": "",
        "darkStyle": ""
      },
      "reverseGeocoding": {
        "enabled": true
      },
      "oauth": {
        "autoLaunch": true,
        "autoRegister": true,
        "buttonText": "Login with ${vars.services.keycloak.subdomain}.${vars.zone}",
        "clientId": "${vars.services.immich.oidcID}",
        "clientSecret": "${vars.sensitive.services.immich.oidcSecret}",
        "defaultStorageQuota": 0,
        "enabled": true,
        "issuerUrl": "https://${vars.services.keycloak.subdomain}.${vars.zone}/realms/master",
        "mobileOverrideEnabled": false,
        "mobileRedirectUri": "",
        "scope": "openid email profile",
        "signingAlgorithm": "RS256",
        "storageLabelClaim": "preferred_username",
        "storageQuotaClaim": "immich_quota"
      },
      "passwordLogin": {
        "enabled": false
      },
      "storageTemplate": {
        "enabled": true,
        "hashVerificationEnabled": true,
        "template": "{{y}}/{{MMMM}}/{{y}}{{MM}}{{dd}}-{{HH}}{{mm}}{{ss}}"
      },
      "image": {
        "thumbnailFormat": "webp",
        "thumbnailSize": 150,
        "previewFormat": "jpeg",
        "previewSize": 1080,
        "quality": 80,
        "colorspace": "p3",
        "extractEmbedded": false
      },
      "newVersionCheck": {
        "enabled": false
      },
      "trash": {
        "enabled": true,
        "days": 30
      },
      "theme": {
        "customCss": ""
      },
      "library": {
        "scan": {
          "enabled": true,
          "cronExpression": "0 0 * * *"
        },
        "watch": {
          "enabled": false,
          "usePolling": false,
          "interval": 10000
        }
      },
      "server": {
        "externalDomain": "https://${vars.services.immich.subdomain + "." + vars.zone}",
        "loginPageMessage": ""
      },
      "notifications": {
        "smtp": {
          "enabled": false,
          "from": "",
          "replyTo": "",
          "transport": {
            "ignoreCert": false,
            "host": "",
            "port": 587,
            "username": "",
            "password": ""
          }
        }
      },
      "user": {
        "deleteDelay": 7
      }
    }
  '';
}
