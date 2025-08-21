{ pkgs, config, ... }:
let
  dataDir = "/mnt/paperless";
in
{
  fileSystems."${dataDir}" = {
    device = "/dev/mapper/2a37-data";
    fsType = "btrfs";
    options = [
      "defaults"
      "nofail"
      "subvol=paperless"
    ];
  };

  sops.secrets."services/paperless/password".owner = "paperless";
  services.paperless = {
    enable = true;
    passwordFile = config.sops.secrets."services/paperless/password".path;
    inherit dataDir;
    configureTika = true;
    database.createLocally = true;
    exporter.enable = true;
    settings = {
      PAPERLESS_OCR_CLEAN = "clean-final";
      PAPERLESS_OCR_LANGUAGE = "fra+eng+rus+lit";
      PAPERLESS_DATE_PARSER_LANGUAGES = "fr+en";
      PAPERLESS_OCR_USER_ARGS = {
        optimize = 2;
      };

      PAPERLESS_CONSUMER_RECURSIVE = true;
      PAPERLESS_CONSUMER_SUBDIRS_AS_TAGS = true;

      PAPERLESS_ENABLE_COMPRESSION = false;
      PAPERLESS_URL = "https://${config.ldryt-infra.dns.records.paperless}";

      PAPERLESS_APPS = "allauth.socialaccount.providers.openid_connect";
      PAPERLESS_SOCIAL_AUTO_SIGNUP = true;
      PAPERLESS_SOCIAL_ACCOUNT_SYNC_GROUPS = true;
      # PAPERLESS_REDIRECT_LOGIN_TO_SSO = true;

      PAPERLESS_EMAIL_HOST = config.ldryt-infra.dns.records.mailserver;
      PAPERLESS_EMAIL_PORT = 587;
      PAPERLESS_EMAIL_HOST_USER = "paperless@ldryt.dev";
      PAPERLESS_EMAIL_USE_TLS = true;
    };
    environmentFile = config.sops.templates."paperless.env".path;
  };

  sops.secrets."services/paperless/oidc/clientSecret".owner = config.services.paperless.user;
  sops.secrets."services/paperless/mail/clearPassword".owner = config.services.paperless.user;
  sops.templates."paperless.env" =
    let
      provider = {
        openid_connect = {
          SCOPE = [
            "openid"
            "profile"
            "email"
            "groups"
          ];
          OAUTH_PKCE_ENABLED = true;
          APPS = [
            {
              provider_id = "authelia";
              name = "Authelia";
              client_id = "M_3u3h400bGpZITw.v4uzY3AcauXnQ2oN-QOBArXDVnN8H6CCk~kF5umSLIlRkG5oV5Nxemv";
              secret = config.sops.placeholder."services/paperless/oidc/clientSecret";
              settings = {
                server_url = "https://${config.ldryt-infra.dns.records.authelia}";
                token_auth_method = "client_secret_basic";
              };
            }
          ];
        };
      };
    in
    {
      owner = config.services.paperless.user;
      content = ''
        PAPERLESS_SOCIALACCOUNT_PROVIDERS=${builtins.toJSON provider}
        PAPERLESS_EMAIL_HOST_PASSWORD=${config.sops.placeholder."services/paperless/mail/clearPassword"}
      '';
    };

  services.nginx.virtualHosts."${config.ldryt-infra.dns.records.paperless}" = {
    enableACME = true;
    forceSSL = true;
    kTLS = true;
    locations."/" = {
      proxyPass = "http://${config.services.paperless.address}:${toString config.services.paperless.port}";
      extraConfig = ''
        client_max_body_size 2G;
      '';
    };
  };

  sops.secrets."backups/restic/repos/paperless/password" = { };
  ldryt-infra.backups.repos.paperless =
    let
      pgdumpTmpDir = "/tmp/paperless-pgdump";
    in
    {
      passwordFile = config.sops.secrets."backups/restic/repos/paperless/password".path;
      paths = [
        pgdumpTmpDir
        dataDir
      ];
      backupPrepareCommand = ''
        set -ex -o pipefail
        umask 077
        mkdir -p "${pgdumpTmpDir}"
        ${config.services.postgresql.package}/bin/pg_dump --clean --create paperless | ${pkgs.zstd}/bin/zstd -c 17 > "${pgdumpTmpDir}/paperless-db-dump.sql.zstd"
      '';
      backupCleanupCommand = ''
        rm -rf "${pgdumpTmpDir}"
      '';
    };
}
