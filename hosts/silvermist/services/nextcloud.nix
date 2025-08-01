{ config, pkgs, ... }:
let
  dns = builtins.fromJSON (builtins.readFile ../../../dns.json);
  dataDir = "/mnt/nextcloud-data";
  backupsTmpDir = "/tmp/nextcloud_backups";
  oidcClientID = "Yn08v8LYLXu81BOva30ja9WAKg9CFSGJ7tXh~PaxTP_mPF1XtajkG8hEnj13cuFJ4FjII55D";
in
{
  sops.secrets."services/nextcloud/adminPassword".owner = "nextcloud";
  sops.secrets."services/nextcloud/secrets".owner = "nextcloud";
  sops.secrets."services/nextcloud/oidcSecret".owner = "nextcloud";
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud29;

    hostName = "${dns.subdomains.nextcloud}.${dns.zone}";
    home = dataDir;
    https = true;
    maxUploadSize = "10G";

    config.adminpassFile = config.sops.secrets."services/nextcloud/adminPassword".path;
    secretFile = config.sops.secrets."services/nextcloud/secrets".path;

    config.dbtype = "pgsql";
    database.createLocally = true;
    configureRedis = true;

    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps)
        user_oidc
        calendar
        mail
        deck
        notes
        contacts
        ;
    };

    settings.user_oidc = {
      use_pkce = true;
      soft_auto_provision = false;
    };
  };

  systemd.services.nextcloud-setup-oidc = {
    enable = true;
    script = ''
      ${config.services.nextcloud.occ}/bin/nextcloud-occ user_oidc:provider authelia-main \
        --clientid="${oidcClientID}" \
        --clientsecret="$(cat ${config.sops.secrets."services/nextcloud/oidcSecret".path})" \
        --discoveryuri="https://${dns.subdomains.authelia}.${dns.zone}/.well-known/openid-configuration"

      ${config.services.nextcloud.occ}/bin/nextcloud-occ config:app:set --value=0 user_oidc allow_multiple_user_backends
    '';
    wantedBy = [ "multi-user.target" ];
    after = [ "nextcloud-setup.service" ];
  };

  services.authelia.instances.main.settings.identity_providers.oidc.clients = [
    {
      client_name = "Nextcloud";
      client_id = oidcClientID;
      client_secret = "$pbkdf2-sha512$310000$vmlFc9aoWutrZykeVwndlg$DrkOquUG9Wqhd7EdGtcuAT0M3nrxPC8SyTyvKJeEt1EqwzQiZbMax38Nl8C1Tsoglq8dyDulByofSR3wlhBwcw";
      public = false;
      require_pkce = true;
      pkce_challenge_method = "S256";
      redirect_uris = [ "https://${dns.subdomains.nextcloud}.${dns.zone}/apps/user_oidc/code" ];
      scopes = [
        "openid"
        "profile"
        "email"
        "groups"
      ];
      userinfo_signed_response_alg = "none";
    }
  ];

  systemd.services.nextcloud-setup.unitConfig.RequiresMountsFor = [ dataDir ];
  services.cachefilesd.enable = true;
  sops.secrets."system/smb/glouton/nextcloud-data/credentials" = { };
  environment.systemPackages = [ pkgs.cifs-utils ];
  fileSystems."${dataDir}" = {
    device = "//u391790-sub4.your-storagebox.de/u391790-sub4";
    fsType = "cifs";
    options = [
      "cred=${config.sops.secrets."system/smb/glouton/nextcloud-data/credentials".path}"

      "uid=nextcloud"
      "forceuid"
      "gid=nextcloud"
      "forcegid"
      "file_mode=0770"
      "dir_mode=0770"

      "vers=3.1.1"
      "sec=ntlmsspi"
      "seal"
      "hard"
      "mfsymlinks"

      "async"
      "noatime"
      "cache=loose"
      "actimeo=3600"
      "locallease"
      "rsize=4194304"
      "wsize=4194304"
      "fsc"
    ];
  };

  services.nginx.virtualHosts.${config.services.nextcloud.hostName} = {
    enableACME = true;
    forceSSL = true;
    kTLS = true;
  };

  sops.secrets."backups/restic/repos/nextcloud/password" = { };
  ldryt-infra.backups.repos.nextcloud = {
    passwordFile = config.sops.secrets."backups/restic/repos/nextcloud/password".path;
    paths = [
      backupsTmpDir
      dataDir
    ];
    backupPrepareCommand = ''
      if ! mkdir -p "${backupsTmpDir}"; then
        echo "Could not create backup folder '${backupsTmpDir}'" >&2
        exit 1
      fi

      ${config.services.nextcloud.occ}/bin/nextcloud-occ maintenance:mode --on

      /run/wrappers/bin/sudo -u postgres \
        ${pkgs.postgresql}/bin/pg_dumpall \
          --host ${config.services.nextcloud.config.dbhost} \
          | ${pkgs.gzip}/bin/gzip > "${backupsTmpDir}/nextcloud-db-dump.sql.gz"
    '';
    backupCleanupCommand = ''
      rm -rf "${backupsTmpDir}"
      ${config.services.nextcloud.occ}/bin/nextcloud-occ maintenance:mode --off
    '';
  };
}
