{ config, pkgs, ... }:
let
  dns = builtins.fromJSON (builtins.readFile ../../../dns.json);
  dataDir = "/mnt/immich-library";
  podmanNetwork = "immich-network";
  internalPort = "44084";
  backupsTmpDir = "/tmp/immich_backups";
  oidcSigningAlg = "RS256";
  oidcClientID = "lDGd-h~eVFyILWKT0uvDA1WGMZXboNdLJC8XL.eqW1UbEIjP~6yyCR5Pv1La5zix73LAf38e";
  immichConfigPath = "/etc/immich.conf";
in
{
  systemd.services.init-immich-network = {
    description = "Create the network named ${podmanNetwork}.";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      check=$(${pkgs.podman}/bin/podman network ls | grep "${podmanNetwork}" || true)
      if [ -z "$check" ];
        then ${pkgs.podman}/bin/podman network create ${podmanNetwork}
        else echo "${podmanNetwork} already exists in podman"
      fi
    '';
  };

  virtualisation.oci-containers.containers = {
    "immich-server" = {
      hostname = "immich-server";
      image = "ghcr.io/immich-app/immich-server:v1.137.1";
      environment = {
        IMMICH_CONFIG_FILE = immichConfigPath;
        DB_HOSTNAME = "immich-db";
        DB_USERNAME = config.virtualisation.oci-containers.containers.immich-db.environment.POSTGRES_USER;
        DB_DATABASE_NAME =
          config.virtualisation.oci-containers.containers.immich-db.environment.POSTGRES_DB;
        DB_PASSWORD =
          config.virtualisation.oci-containers.containers.immich-db.environment.POSTGRES_PASSWORD;
        REDIS_HOSTNAME = "immich-redis";
      };
      volumes = [
        "${immichConfigPath}:${immichConfigPath}:ro"
        "${dataDir}:/usr/src/app/upload"
      ];
      ports = [ "127.0.0.1:${internalPort}:2283" ];
      dependsOn = [
        "immich-redis"
        "immich-db"
      ];
      extraOptions = [ "--network=${podmanNetwork}" ];
    };
    "immich-machine-learning" = {
      hostname = "immich-machine-learning";
      image = "ghcr.io/immich-app/immich-machine-learning:v1.137.1";
      volumes = [ "immich-ml-cache:/cache" ];
      extraOptions = [ "--network=${podmanNetwork}" ];
    };
    "immich-db" = {
      hostname = "immich-db";
      image = "ghcr.io/immich-app/postgres:14-vectorchord0.3.0-pgvectors0.2.0";
      environment = {
        POSTGRES_PASSWORD = "postgres";
        POSTGRES_USER = "postgres";
        POSTGRES_DB = "immich";
        POSTGRES_INITDB_ARGS = "--data-checksums";
      };
      volumes = [ "immich-db-data:/var/lib/postgresql/data" ];
      extraOptions = [ "--network=${podmanNetwork}" ];
    };
    "immich-redis" = {
      hostname = "immich-redis";
      image = "docker.io/valkey/valkey:8-bookworm@sha256:42cba146593a5ea9a622002c1b7cba5da7be248650cbb64ecb9c6c33d29794b1";
      extraOptions = [ "--network=${podmanNetwork}" ];
    };
  };

  sops.secrets."system/smb/glouton/immich-library/credentials" = { };
  environment.systemPackages = [ pkgs.cifs-utils ];
  fileSystems."${dataDir}" = {
    device = "//u391790-sub1.your-storagebox.de/u391790-sub1";
    fsType = "cifs";
    options = [
      "async,rw,auto,nofail,credentials=${
        config.sops.secrets."system/smb/glouton/immich-library/credentials".path
      },uid=${toString config.users.users.colon.uid},fsc,noauto,x-systemd.automount,x-systemd.idle-timeout=60,x-systemd.mount-timeout=5s"
    ];
  };

  services.nginx.virtualHosts."${dns.subdomains.immich}.${dns.zone}" = {
    enableACME = true;
    forceSSL = true;
    kTLS = true;
    locations."/" = {
      proxyWebsockets = true;
      proxyPass = "http://127.0.0.1:${internalPort}";
      extraConfig = ''
        client_max_body_size 0;
      '';
    };
  };

  services.authelia.instances.main.settings.identity_providers.oidc.clients = [
    {
      client_name = "immich";
      client_id = oidcClientID;
      client_secret = "$pbkdf2-sha512$310000$Huutr5ZUtLI/eUqou676MA$p2z9qxBbkkjkDoPni55VAfCP4gO4TzE78Vob2FbLfhAn3syHa6/97NjHhyVsz9B7xWB2lkkiYDtCs6jBC1th4w";
      public = false;
      consent_mode = "implicit";
      redirect_uris = [
        "https://${dns.subdomains.immich}.${dns.zone}/auth/login"
        "https://${dns.subdomains.immich}.${dns.zone}/user-settings"
        "app.immich:///oauth-callback"
      ];
      scopes = [
        "openid"
        "profile"
        "email"
      ];
      userinfo_signed_response_alg = oidcSigningAlg;
      id_token_signed_response_alg = oidcSigningAlg;

      # https://github.com/immich-app/immich/releases/tag/v1.132.3
      token_endpoint_auth_method = "client_secret_post";
    }
  ];

  sops.secrets."backups/restic/repos/immich/password" = { };
  ldryt-infra.backups.repos.immich = {
    passwordFile = config.sops.secrets."backups/restic/repos/immich/password".path;
    paths = [
      backupsTmpDir
      dataDir
    ];
    backupPrepareCommand = ''
      ${pkgs.bash}/bin/bash -c '
        if ! mkdir -p "${backupsTmpDir}"; then
          echo "Could not create backup folder '${backupsTmpDir}'" >&2
          exit 1
        fi

        ${pkgs.podman}/bin/podman exec -t immich-db pg_dumpall -c -U postgres | ${pkgs.gzip}/bin/gzip > "${backupsTmpDir}/immich-db-dump.sql.gz"
      '
    '';
    backupCleanupCommand = ''
      ${pkgs.bash}/bin/bash -c 'rm -rf "${backupsTmpDir}"'
    '';
  };

  sops.secrets."services/immich/oidc/clientSecret".owner = config.users.users.colon.name;
  systemd.services."${config.virtualisation.oci-containers.backend}-immich-server".serviceConfig.ExecStartPre =
    let
      oauthClientSecretPlaceholder = "SUPPOSED_TO_BE_REPLACED_AUTOMATICALLY";
      immichConfig = pkgs.writeText "immich-config.json" ''
        ffmpeg:
          transcode: all
          crf: 30
          preset: medium
          targetVideoCodec: vp9
          targetAudioCodec: libopus
          targetResolution: '720'
          twoPass: true
          tonemap: reinhard
        oauth:
          enabled: true
          issuerUrl: https://${dns.subdomains.authelia}.${dns.zone}/.well-known/openid-configuration
          clientId: ${oidcClientID}
          clientSecret: ${oauthClientSecretPlaceholder}
          signingAlgorithm: ${oidcSigningAlg}
          profileSigningAlgorithm: ${oidcSigningAlg}
          scope: openid email profile
          storageLabelClaim: preferred_username
          storageQuotaClaim: immich_quota
          buttonText: Login with ${dns.subdomains.authelia}.${dns.zone}
          defaultStorageQuota: 0
          autoRegister: true
        machineLearning:
          clip:
            modelName: ViT-B-16-SigLIP-384__webli
        passwordLogin:
          enabled: false
        storageTemplate:
          enabled: true
          hashVerificationEnabled: true
          template: '{{y}}/{{MMMM}}/{{y}}{{MM}}{{dd}}-{{HH}}{{mm}}{{ss}}'
        image:
          thumbnail:
            quality: 85
          preview:
            quality: 85
        server:
          externalDomain: https://${dns.subdomains.immich}.${dns.zone}
        notifications:
          smtp:
            enabled: true
            from: pics@ldryt.dev
            replyTo: noreply@ldryt.dev
            transport:
              host: localhost
              port: 25
      '';
    in
    [
      (pkgs.writeShellScript "immich-config-inject-secrets.sh" ''
        oauth_client_secret=$(cat ${config.sops.secrets."services/immich/oidc/clientSecret".path})
        install -D -o ${config.users.users.colon.name} -m 0400 "${immichConfig}" "${immichConfigPath}"
        ${pkgs.busybox}/bin/sed -i 's/${oauthClientSecretPlaceholder}/'"$oauth_client_secret"'/g' "${immichConfigPath}"
      '')
    ];
}
