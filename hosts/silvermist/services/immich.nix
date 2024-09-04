{ config, pkgs, ... }:
let
  dns = builtins.fromJSON (builtins.readFile ../dns.json);
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

  sops.secrets."services/immich/credentials".owner = config.users.users.colon.name;
  virtualisation.oci-containers.containers = {
    "immich-server" = {
      hostname = "immich-server";
      image = "ghcr.io/immich-app/immich-server:v1.113.1@sha256:baf001a57dbb8b088a81564c00f794a2374e17e64e96219f1062c3330d2ba5c0"; # https://github.com/immich-app/immich/pkgs/container/immich-server/267646755?tag=v1.113.1
      environment = {
        IMMICH_CONFIG_FILE = immichConfigPath;
        DB_HOSTNAME = "immich-db";
        DB_USERNAME = config.virtualisation.oci-containers.containers.immich-db.environment.POSTGRES_USER;
        DB_DATABASE_NAME =
          config.virtualisation.oci-containers.containers.immich-db.environment.POSTGRES_DB;
        DB_PASSWORD = "\${DB_PASSWORD:?error message}";
        REDIS_HOSTNAME = "immich-redis";
      };
      environmentFiles = [ "${config.sops.secrets."services/immich/credentials".path}" ];
      volumes = [
        "${immichConfigPath}:${immichConfigPath}:ro"
        "${dataDir}:/usr/src/app/upload"
        "/etc/localtime:/etc/localtime:ro"
      ];
      ports = [ "127.0.0.1:${internalPort}:3001" ];
      dependsOn = [
        "immich-redis"
        "immich-db"
      ];
      extraOptions = [ "--network=${podmanNetwork}" ];
    };
    "immich-machine-learning" = {
      hostname = "immich-machine-learning";
      image = "ghcr.io/immich-app/immich-machine-learning:v1.113.1@sha256:c18fa0f383eca9d2b78c781b2c852719fe0d6a966e0333b5931d80132fce64e4"; # https://github.com/immich-app/immich/pkgs/container/immich-machine-learning/267651544?tag=v1.113.1
      volumes = [ "immich-ml-cache:/cache" ];
      extraOptions = [ "--network=${podmanNetwork}" ];
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
      extraOptions = [ "--network=${podmanNetwork}" ];
    };
    "immich-redis" = {
      hostname = "immich-redis";
      image = "docker.io/library/redis:6.2-alpine@sha256:84882e87b54734154586e5f8abd4dce69fe7311315e2fc6d67c29614c8de2672";
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
      },uid=${toString config.users.users.colon.uid},cache=loose,fsc"
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
      authorization_policy = "two_factor";
      redirect_uris = [
        "https://${dns.subdomains.immich}.${dns.zone}/auth/login"
        "https://${dns.subdomains.immich}.${dns.zone}/user-settings"
        "app.immich:/"
      ];
      scopes = [
        "openid"
        "profile"
        "email"
      ];
      userinfo_signed_response_alg = oidcSigningAlg;
      id_token_signed_response_alg = oidcSigningAlg;
    }
  ];

  ldryt-infra.backups.immich = {
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
        passwordLogin:
          enabled: false
        storageTemplate:
          enabled: true
          hashVerificationEnabled: true
          template: '{{y}}/{{MMMM}}/{{y}}{{MM}}{{dd}}-{{HH}}{{mm}}{{ss}}'
        image:
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
