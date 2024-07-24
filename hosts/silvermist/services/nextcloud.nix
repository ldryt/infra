{ config, pkgs, ... }:
let
  dns = builtins.fromJSON (builtins.readFile ../dns.json);
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
    https = true;
    maxUploadSize = "10G";

    home = "/var/lib/nextcloud";
    datadir = dataDir;

    config.adminpassFile = config.sops.secrets."services/nextcloud/adminPassword".path;
    secretFile = config.sops.secrets."services/nextcloud/secrets".path;

    config.dbtype = "pgsql";
    database.createLocally = true;

    settings.cache_path = "${config.services.nextcloud.home}/cache/$user";
    configureRedis = true;
    notify_push.enable = true;

    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps) user_oidc calendar deck;
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
        --clientsecret="$(sudo -u nextcloud cat ${config.sops.secrets."services/nextcloud/oidcSecret".path})" \
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
      authorization_policy = "two_factor";
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
      token_endpoint_auth_method = "client_secret_post";
    }
  ];

  sops.secrets."system/smb/glouton/nextcloud-data/credentials" = { };
  environment.systemPackages = [ pkgs.cifs-utils ];
  fileSystems."${dataDir}" = {
    device = "//u391790-sub4.your-storagebox.de/u391790-sub4";
    fsType = "cifs";
    options = [
      "async,rw,auto,nofail,credentials=${
        config.sops.secrets."system/smb/glouton/nextcloud-data/credentials".path
      },uid=${toString config.users.users.colon.uid},cache=loose,fsc"
    ];
  };

  services.nginx.virtualHosts.${config.services.nextcloud.hostName} = {
    enableACME = true;
    forceSSL = true;
    kTLS = true;
  };

  ldryt-infra.backups.nextcloud = {
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

      ${pkgs.postgresql}/bin/pg_dump ${config.services.nextcloud.config.dbname} \
        --host ${config.services.nextcloud.config.dbhost} \
        --username ${config.services.nextcloud.config.dbuser} \
        | ${pkgs.gzip}/bin/gzip > "${backupsTmpDir}/nextcloud-db-dump.sql.gz"
    '';
    backupCleanupCommand = ''
      rm -rf "${backupsTmpDir}"
      ${config.services.nextcloud.occ}/bin/nextcloud-occ maintenance:mode --off
    '';
  };
}
