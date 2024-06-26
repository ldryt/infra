{
  config,
  pkgs,
  dns,
  ...
}:
let
  backupsTmpDir = "/tmp/bitwarden_rs_backup";
  dataDir = "/var/lib/bitwarden_rs";
in
{
  services.vaultwarden = {
    enable = true;
    config = {
      DOMAIN = "https://${dns.silvermist.subdomains.vaultwarden}.${dns.silvermist.zone}";
      SIGNUPS_ALLOWED = "true";
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 44083;
      DATA_FOLDER = dataDir;
    };
  };

  services.nginx.virtualHosts."${dns.silvermist.subdomains.vaultwarden}.${dns.silvermist.zone}" = {
    enableACME = true;
    forceSSL = true;
    kTLS = true;
    locations."/" = {
      proxyWebsockets = true;
      proxyPass = "http://${config.services.vaultwarden.config.ROCKET_ADDRESS}:${toString config.services.vaultwarden.config.ROCKET_PORT}";
    };
  };

  ldryt-infra.backups.vaultwarden = {
    paths = [ backupsTmpDir ];
    # https://github.com/NixOS/nixpkgs/blob/592047fc9e4f7b74a4dc85d1b9f5243dfe4899e3/nixos/modules/services/security/vaultwarden/backup.sh
    backupPrepareCommand = ''
      ${pkgs.bash}/bin/bash -c '
        if ! mkdir -p "${backupsTmpDir}"; then
          echo "Could not create backup folder '${backupsTmpDir}'" >&2
          exit 1
        fi

        if [[ ! -f "${dataDir}"/db.sqlite3 ]]; then
          echo "Could not find SQLite database file '${dataDir}/db.sqlite3'" >&2
          exit 1
        fi

        ${pkgs.sqlite}/bin/sqlite3 "${dataDir}"/db.sqlite3 ".backup '${backupsTmpDir}/db.sqlite3'"
        cp "${dataDir}"/rsa_key.{der,pem,pub.der} "${backupsTmpDir}"
        cp -r "${dataDir}"/attachments "${backupsTmpDir}"
        cp -r "${dataDir}"/sends "${backupsTmpDir}"
      '
    '';
    backupCleanupCommand = ''
      ${pkgs.bash}/bin/bash -c 'rm -rf "${backupsTmpDir}"'
    '';
  };
}
