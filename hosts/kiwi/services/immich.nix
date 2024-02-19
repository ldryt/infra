{ config, pkgs, ... }:
let
  hidden = import ../../../secrets/obfuscated.nix;
  immichSubdomain = "pics";
  immichLibraryDirName = "immich-library";
  immichOidcID = "immich-clients";
  immichNetworkName = "immich-bridge";
  immichExposedPort = "44084";
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
        "url": "http://immich-machine-learning:3003",
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
  systemd.services.init-immich-network = {
    description = "Create the network named ${immichNetworkName}.";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      check=$(${pkgs.podman}/bin/podman network ls | grep "${immichNetworkName}" || true)
      if [ -z "$check" ];
        then ${pkgs.podman}/bin/podman network create ${immichNetworkName}
        else echo "${immichNetworkName} already exists in podman"
      fi
    '';
  };

  virtualisation.oci-containers.containers = {
    "immich-server" = {
      hostname = "immich-server";
      image =
        "ghcr.io/immich-app/immich-server:v1.94.1@sha256:e0655cdd4351a8406eb87ec379a9c45e7bc2a9d051d25c93e2953d92e01713b6";
      cmd = [ "start.sh" "immich" ];
      environment = {
        IMMICH_CONFIG_FILE = "/etc/immich-config.json";
        DB_HOSTNAME = "immich-db";
        DB_USERNAME =
          config.virtualisation.oci-containers.containers.immich-db.environment.POSTGRES_USER;
        DB_DATABASE_NAME =
          config.virtualisation.oci-containers.containers.immich-db.environment.POSTGRES_DB;
        DB_PASSWORD = "\${DB_PASSWORD:?error message}";
        REDIS_HOSTNAME = "immich-redis";
      };
      environmentFiles =
        [ "${config.sops.secrets."services/immich/credentials".path}" ];
      volumes = [
        "${immichConfigFile}:/etc/immich-config.json:ro"
        "${gloutonPath}/${immichLibraryDirName}:/usr/src/app/upload/library"
        "immich-data:/usr/src/app/upload"
        "/etc/localtime:/etc/localtime:ro"
      ];
      ports = [ "${immichExposedPort}:3001" ];
      dependsOn = [ "immich-redis" "immich-db" ];
      extraOptions = [ "--network=${immichNetworkName}" ];
    };
    "immich-microservices" = {
      hostname = "immich-microservices";
      image =
        config.virtualisation.oci-containers.containers.immich-server.image;
      cmd = [ "start.sh" "microservices" ];
      environment =
        config.virtualisation.oci-containers.containers.immich-server.environment;
      environmentFiles =
        config.virtualisation.oci-containers.containers.immich-server.environmentFiles;
      volumes =
        config.virtualisation.oci-containers.containers.immich-server.volumes;
      dependsOn = [ "immich-redis" "immich-db" ];
      extraOptions = [ "--network=${immichNetworkName}" ];
    };
    "immich-machine-learning" = {
      hostname = "immich-machine-learning";
      image =
        "ghcr.io/immich-app/immich-machine-learning:v1.94.1@sha256:48a9f0056983703b1f50728b4e4dd4879f3bff307579910c00a4f62204f113dc";
      volumes = [ "immich-ml-cache:/cache" ];
      extraOptions = [ "--network=${immichNetworkName}" ];
    };
    "immich-db" = {
      hostname = "immich-db";
      image =
        "docker.io/tensorchord/pgvecto-rs:pg14-v0.1.11@sha256:0335a1a22f8c5dd1b697f14f079934f5152eaaa216c09b61e293be285491f8ee";
      environment = {
        POSTGRES_PASSWORD = "\${DB_PASSWORD:?error message}";
        POSTGRES_USER = "postgres";
        POSTGRES_DB = "immich";
      };
      volumes = [ "immich-db-data:/var/lib/postgresql/data" ];
      environmentFiles =
        config.virtualisation.oci-containers.containers.immich-server.environmentFiles;
      extraOptions = [ "--network=${immichNetworkName}" ];
    };
    "immich-redis" = {
      hostname = "immich-redis";
      image =
        "docker.io/library/redis:6.2-alpine@sha256:afb290a0a0d0b2bd7537b62ebff1eb84d045c757c1c31ca2ca48c79536c0de82";
      extraOptions = [ "--network=${immichNetworkName}" ];
    };
  };

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
        proxyPass = "http://127.0.0.1:${immichExposedPort}";
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
