{
  lib,
  pkgs,
  config,
  ...
}:
let
  dataDir = "/var/lib/lldap";
  backupsTmpDir = "/tmp/lldap-backup";
  dns = builtins.fromJSON (builtins.readFile ../dns.json);
in
{
  users.users.lldap = {
    name = "lldap";
    group = "lldap";
    isSystemUser = true;
  };
  users.groups.lldap = { };

  environment.persistence.silvermist.directories = [
    {
      directory = dataDir;
      user = config.users.users.lldap.name;
      mode = "0750";
    }
  ];

  systemd.services.lldap.serviceConfig.DynamicUser = lib.mkForce false;

  sops.secrets."services/lldap/jwt".owner = config.users.users.lldap.name;
  sops.secrets."services/lldap/admin/password".owner = config.users.users.lldap.name;
  services.lldap = {
    enable = true;
    environment = {
      LLDAP_JWT_SECRET_FILE = config.sops.secrets."services/lldap/jwt".path;
      LLDAP_LDAP_USER_PASS_FILE = config.sops.secrets."services/lldap/admin/password".path;
    };
    settings = {
      verbose = false;

      ldap_host = "127.0.0.1";
      ldap_port = 3890;

      http_host = "127.0.0.1";
      http_port = 8017;
      http_url = "https://${dns.subdomains.lldap}.${dns.zone}";

      ldap_base_dn = "dc=ldryt,dc=dev";
      ldap_user_dn = "admin";
      force_ldap_user_pass_reset = "always";

      database_url = "sqlite://${dataDir}/users.db?mode=rwc";
    };
  };

  services.nginx.virtualHosts."${dns.subdomains.lldap}.${dns.zone}" = {
    enableACME = true;
    forceSSL = true;
    kTLS = true;
    locations."/".proxyPass =
      "http://${config.services.lldap.settings.http_host}:${toString config.services.lldap.settings.http_port}";
  };

  ldryt-infra.backups.lldap = {
    paths = [ backupsTmpDir ];
    backupPrepareCommand = ''
      ${pkgs.bash}/bin/bash -c '
        if ! mkdir -p "${backupsTmpDir}"; then
          echo "Could not create backup folder '${backupsTmpDir}'" >&2
          exit 1
        fi

        if [[ ! -f "${dataDir}"/users.db ]]; then
          echo "Could not find SQLite database file '${dataDir}/users.db'" >&2
          exit 1
        fi

        ${pkgs.sqlite}/bin/sqlite3 "${dataDir}"/users.db ".backup '${backupsTmpDir}/users.db'"
      '
    '';
    backupCleanupCommand = ''
      ${pkgs.bash}/bin/bash -c 'rm -rf "${backupsTmpDir}"'
    '';
  };
}
