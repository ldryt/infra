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
      image = "ghcr.io/immich-app/immich-server:v1.100.0@sha256:4d9040b4199e38374d4b8041437ed708a6c9dfab5b381aff7142402ca824d413";
      cmd = [
        "start.sh"
        "immich"
      ];
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
    "immich-microservices" = {
      hostname = "immich-microservices";
      image = config.virtualisation.oci-containers.containers.immich-server.image;
      cmd = [
        "start.sh"
        "microservices"
      ];
      environment = config.virtualisation.oci-containers.containers.immich-server.environment;
      environmentFiles = config.virtualisation.oci-containers.containers.immich-server.environmentFiles;
      volumes = config.virtualisation.oci-containers.containers.immich-server.volumes;
      dependsOn = [
        "immich-redis"
        "immich-db"
      ];
      extraOptions = [ "--network=${vars.services.immich.podmanNetwork}" ];
    };
    "immich-machine-learning" = {
      hostname = "immich-machine-learning";
      image = "ghcr.io/immich-app/immich-machine-learning:v1.100.0@sha256:ddf76a30d2a6f30cef1535b2538f55037dee96b889f34394319fadec9d49db62";
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
      image = "docker.io/library/redis:6.2-alpine@sha256:afb290a0a0d0b2bd7537b62ebff1eb84d045c757c1c31ca2ca48c79536c0de82";
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

  services.caddy.virtualHosts."${vars.services.immich.subdomain + "." + vars.zone}".extraConfig = ''
    header {
      -Server
      Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
      X-Xss-Protection "1; mode=block"
      X-Content-Type-Options "nosniff"
      X-Frame-Options "DENY"
      Permissions-Policy interest-cohort=()
      Content-Security-Policy "upgrade-insecure-requests"
      Referrer-Policy "strict-origin-when-cross-origin"
      Cache-Control "public, max-age=15, must-revalidate"
      Feature-Policy "accelerometer 'none'; ambient-light-sensor 'none'; autoplay 'self'; camera 'none'; encrypted-media 'none'; fullscreen 'self'; geolocation 'none'; gyroscope 'none';       magnetometer 'none'; microphone 'none'; midi 'none'; payment 'none'; picture-in-picture *; speaker 'none'; sync-xhr 'none'; usb 'none'; vr 'none'"
    }
    reverse_proxy http://127.0.0.1:${vars.services.immich.internalPort}
  '';

  services.authelia.instances."ldryt".settings.identity_providers.oidc = {
    access_token_lifespan = "2d";
    refresh_token_lifespan = "3d";

    clients = [
      {
        description = "Immich Clients";
        id = vars.services.immich.oidcID;
        secret = vars.sensitive.services.immich.oidcSecret;
        public = false;
        consent_mode = "implicit";
        authorization_policy = "two_factor";
        scopes = [
          "email"
          "groups"
          "openid"
          "profile"
        ];
        redirect_uris = [
          "https://${vars.services.immich.subdomain + "." + vars.zone}"
          "https://${vars.services.immich.subdomain + "." + vars.zone}/auth/login"
          "https://${vars.services.immich.subdomain + "." + vars.zone}/user-settings"
          "https://${vars.services.immich.subdomain + "." + vars.zone}/oauth2/callback"
          "https://${vars.services.immich.subdomain + "." + vars.zone}/api/oauth/mobile-redirect"
          "app.immich:/"
        ];
        userinfo_signing_algorithm = "none";
        response_types = [ "code" ];
        response_modes = [
          "form_post"
          "query"
          "fragment"
        ];
        grant_types = [
          "refresh_token"
          "authorization_code"
        ];
      }
    ];
  };

  sops.secrets."backups/restic/immich/repositoryPass".owner = "root";
  sops.secrets."backups/restic/immich/sshKey".owner = "root";
  services.restic.backups.immich = {
    user = "root";
    backupPrepareCommand = ''
      ${pkgs.bash}/bin/bash -c '
        if ! mkdir -p "${vars.services.immich.backups.tmpDir}"; then
          echo "Could not create backup folder '${vars.services.immich.backups.tmpDir}'" >&2
          exit 1
        fi

        ${pkgs.podman}/bin/podman exec -t immich-db pg_dumpall -c -U postgres | ${pkgs.gzip}/bin/gzip > "${vars.services.immich.backups.tmpDir}/immich-db-dump.sql.gz"
      '
    '';
    paths = [
      vars.services.immich.backups.tmpDir
      vars.services.immich.dataDir
    ];
    repository = "sftp:${
      vars.sensitive.backups.user + "@" + vars.sensitive.backups.host
    }:restic-repo-immich";
    extraOptions = [
      "sftp.command='ssh ${vars.sensitive.backups.user + "@" + vars.sensitive.backups.host} -p 23 -i ${
        config.sops.secrets."backups/restic/immich/sshKey".path
      } -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -s sftp'"
    ];
    initialize = true;
    passwordFile = config.sops.secrets."backups/restic/immich/repositoryPass".path;
    backupCleanupCommand = ''
      ${pkgs.bash}/bin/bash -c 'rm -rf "${vars.services.immich.backups.tmpDir}"'
    '';
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 8"
      "--keep-monthly 12"
      "--keep-yearly 100"
    ];
    timerConfig = {
      OnCalendar = "daily";
      RandomizedDelaySec = "6h";
      Persistent = true;
    };
  };

  environment.etc."immich/config.json".text = ''
    {
      "ffmpeg": {
        "crf": 30,
        "threads": 0,
        "preset": "slower",
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
          "concurrency": 1
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
        "facialRecognition": {
          "enabled": true,
          "modelName": "buffalo_l",
          "minScore": 0.8,
          "maxDistance": 0.5,
          "minFaces": 7
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
        "enabled": true,
        "issuerUrl": "https://${vars.services.keycloak.subdomain}.${vars.zone}/realms/master",
        "clientId": "${vars.services.immich.oidcID}",
        "clientSecret": "${vars.sensitive.services.immich.oidcSecret}",
        "scope": "openid email profile",
        "storageLabelClaim": "preferred_username",
        "buttonText": "Login with ${vars.services.keycloak.subdomain}.${vars.zone}",
        "autoRegister": true,
        "autoLaunch": true
      },
      "passwordLogin": {
        "enabled": false
      },
      "storageTemplate": {
        "enabled": true,
        "hashVerificationEnabled": true,
        "template": "{{y}}/{{MMMM}}/{{y}}{{MM}}{{dd}}-{{HH}}{{mm}}{{ss}}"
      },
      "thumbnail": {
        "webpSize": 200,
        "jpegSize": 1080,
        "quality": 88,
        "colorspace": "p3"
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
      }
    }
  '';
}
