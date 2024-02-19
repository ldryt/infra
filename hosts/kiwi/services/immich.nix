{ config, pkgs, ... }:
let
  hidden = import ../../../secrets/obfuscated.nix;
  immichSubdomain = "pics";
  immichLibraryDirName = "immich-library";
  immichOidcID = "immich-clients";
  autheliaSubdomain = "iam";
  gloutonPath = "/mnt/glouton";
  immichConfigFile = pkgs.writeText "immich-config.json" ''
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
        "url": "http://127.0.0.1:${config.virtualisation.oci-containers.containers.immich-server.environment.MACHINE_LEARNING_PORT}",
        "clip": {
          "enabled": true,
          "modelName": "immich-app/ViT-g-14__laion2b-s12b-b42k"
        },
        "facialRecognition": {
          "enabled": true,
          "modelName": "buffalo_l",
          "minScore": 0.8,
          "maxDistance": 0.5,
          "minFaces": 7
        },
        "classification": {
          "minScore": 0.8
        }
      },
      "map": {
        "enabled": true,
        "lightStyle": "",
        "darkStyle": ""
      },
      "reverseGeocoding": {
        "enabled": true,
        "citiesFileOverride": "cities1000"
      },
      "oauth": {
        "enabled": true,
        "issuerUrl": "https://${autheliaSubdomain}.${hidden.ldryt.host}",
        "clientId": "${immichOidcID}",
        "clientSecret": "${hidden.kiwi.immich.oidcSecret}",
        "mobileOverrideEnabled": true,
        "mobileRedirectUri": "https://${immichSubdomain}.${hidden.ldryt.host}/api/oauth/mobile-redirect",
        "scope": "openid email profile",
        "storageLabelClaim": "preferred_username",
        "buttonText": "Login with Authelia",
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
        "externalDomain": "https://${immichSubdomain}.${hidden.ldryt.host}",
        "loginPageMessage": ""
      }
    }
  '';
in {
  virtualisation.oci-containers.containers = {
    "immich-server" = {
      image =
        "ghcr.io/immich-app/immich-server@sha256:d9f8e64eb56a82fa80cd285dfb6a6ecb54495725de9c2914755c47762815701d";
      cmd = [ "start.sh" "immich" ];
      environment = {
        SERVER_PORT = "44071";
        MICROSERVICES_PORT = "44072";
        MACHINE_LEARNING_PORT = "44073";
        IMMICH_SERVER_URL =
          "http://127.0.0.1:${config.virtualisation.oci-containers.containers.immich-server.environment.SERVER_PORT}";
        IMMICH_MACHINE_LEARNING_URL =
          "http://127.0.0.1:${config.virtualisation.oci-containers.containers.immich-server.environment.MACHINE_LEARNING_PORT}";
        IMMICH_CONFIG_FILE = "/etc/immich/config.json";
        DB_HOSTNAME = "127.0.0.1";
        DB_PORT =
          config.virtualisation.oci-containers.containers.immich-db.environment.PGPORT;
        DB_USERNAME =
          config.virtualisation.oci-containers.containers.immich-db.environment.POSTGRES_USER;
        DB_DATABASE_NAME =
          config.virtualisation.oci-containers.containers.immich-db.environment.POSTGRES_DB;
        DB_PASSWORD = "\${DB_PASSWORD:?error message}";
        REDIS_SOCKET = "/redis.sock";
      };
      environmentFiles =
        [ "${config.sops.secrets."services/immich/credentials".path}" ];
      volumes = [
        "${immichConfigFile}:/etc/immich/config.json:ro"
        "${gloutonPath}/${immichLibraryDirName}:/usr/src/app/upload/library"
        "immich-data:/usr/src/app/upload"
        "/etc/localtime:/etc/localtime:ro"
        "${config.services.redis.servers.immich.unixSocket}:/redis.sock"
      ];
      extraOptions = [ "--network=host" ];
    };
    "immich-microservices" = {
      image =
        config.virtualisation.oci-containers.containers.immich-server.image;
      command = [ "start.sh" "microservices" ];
      environment =
        config.virtualisation.oci-containers.containers.immich-server.environment;
      environmentFiles =
        config.virtualisation.oci-containers.containers.immich-server.environmentFiles;
      volumes =
        config.virtualisation.oci-containers.containers.immich-server.volumes;
    };
    "immich-machine-learning" = {
      image =
        "ghcr.io/immich-app/immich-machine-learning@sha256:303242f61f5739e059a68dcdcca9ec555d5a36cb3b5b8951e6cb452909d55628";
      volumes = [ "immich-ml-cache:/cache" ];
      extraOptions = [ "--network=host" ];
    };
    "immich-db" = {
      image =
        "docker.io/tensorchord/pgvecto-rs:pg14-v0.1.11@sha256:0335a1a22f8c5dd1b697f14f079934f5152eaaa216c09b61e293be285491f8ee";
      environment = {
        POSTGRES_PASSWORD = "\${DB_PASSWORD:?error message}";
        POSTGRES_USER = "immich";
        POSTGRES_DB = "immich";
        PGPORT = "44052";
      };
      volumes = [ "immich-db-data:/var/lib/postgresql" ];
      extraOptions = [ "--network=host" ];
    };
  };

  services.redis.servers."immich".user = "colon";

  environment.systemPackages = [ pkgs.cifs-utils ];
  fileSystems."${gloutonPath}/${immichLibraryDirName}" = {
    device = hidden.kiwi.smb.glouton.${immichLibraryDirName}.shareName;
    fsType = "cifs";
    options = [
      "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s,credentials=${
        config.sops.secrets."system/smb/glouton/${immichLibraryDirName}/credentials".path
      },uid=${toString config.users.users.colon.uid},cache=loose,fsc,sfu"
    ];
  };

  services.nginx = {
    virtualHosts."${immichSubdomain}.${hidden.ldryt.host}" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        recommendedProxySettings = true;
        proxyPass =
          "http://127.0.0.1:${config.virtualisation.oci-containers.containers.immich.environment.SERVER_PORT}";
        extraConfig = ''
          proxy_http_version 1.1;
          proxy_set_header   Upgrade    $http_upgrade;
          proxy_set_header   Connection "upgrade";
          proxy_redirect off;

          proxy_buffers 4 256k;
          proxy_buffer_size 128k;
          proxy_busy_buffers_size 256k;

          client_max_body_size 0;
        '';
      };
    };
  };

  services.authelia.instances."ldryt".settings.identity_providers.oidc = {
    access_token_lifespan = "2d";
    refresh_token_lifespan = "3d";

    clients = [{
      description = "Immich Clients";
      id = "${immichOidcID}";
      secret = hidden.kiwi.immich.oidcSecret;
      public = false;
      consent_mode = "explicit";
      authorization_policy = "two_factor";
      scopes = [ "email" "groups" "openid" "profile" ];
      redirect_uris = [
        "https://${immichSubdomain}.${hidden.ldryt.host}"
        "https://${immichSubdomain}.${hidden.ldryt.host}/auth/login"
        "https://${immichSubdomain}.${hidden.ldryt.host}/user-settings"
        "https://${immichSubdomain}.${hidden.ldryt.host}/oauth2/callback"
        "https://${immichSubdomain}.${hidden.ldryt.host}/api/oauth/mobile-redirect"
        "app.immich:/"
      ];
      userinfo_signing_algorithm = "none";
      response_types = [ "code" ];
      response_modes = [ "form_post" "query" "fragment" ];
      grant_types = [ "refresh_token" "authorization_code" ];
    }];
  };
}
