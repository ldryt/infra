{
  config,
  pkgs,
  vars,
  ...
}:
{
  services.vaultwarden = {
    enable = true;
    config = {
      DOMAIN = "https://${vars.services.vaultwarden.subdomain + "." + vars.zone}";
      SIGNUPS_ALLOWED = "true";
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 44083;
    };
  };

  services.nginx.virtualHosts."${vars.services.vaultwarden.subdomain}.${vars.zone}" = {
    enableACME = true;
    forceSSL = true;
    kTLS = true;
    locations."/" = {
      proxyWebsockets = true;
      proxyPass = "http://${config.services.vaultwarden.config.ROCKET_ADDRESS}:${toString config.services.vaultwarden.config.ROCKET_PORT}";
    };
  };

  ldryt-infra.backups.vaultwarden = {
    paths = [ vars.services.vaultwarden.backups.tmpDir ];
    # https://github.com/NixOS/nixpkgs/blob/592047fc9e4f7b74a4dc85d1b9f5243dfe4899e3/nixos/modules/services/security/vaultwarden/backup.sh
    backupPrepareCommand = ''
      ${pkgs.bash}/bin/bash -c '
        if ! mkdir -p "${vars.services.vaultwarden.backups.tmpDir}"; then
          echo "Could not create backup folder '${vars.services.vaultwarden.backups.tmpDir}'" >&2
          exit 1
        fi

        if [[ ! -f "${vars.services.vaultwarden.dataDir}"/db.sqlite3 ]]; then
          echo "Could not find SQLite database file '${vars.services.vaultwarden.dataDir}/db.sqlite3'" >&2
          exit 1
        fi

        ${pkgs.sqlite}/bin/sqlite3 "${vars.services.vaultwarden.dataDir}"/db.sqlite3 ".backup '${vars.services.vaultwarden.backups.tmpDir}/db.sqlite3'"
        cp "${vars.services.vaultwarden.dataDir}"/rsa_key.{der,pem,pub.der} "${vars.services.vaultwarden.backups.tmpDir}"
        cp -r "${vars.services.vaultwarden.dataDir}"/attachments "${vars.services.vaultwarden.backups.tmpDir}"
        cp -r "${vars.services.vaultwarden.dataDir}"/sends "${vars.services.vaultwarden.backups.tmpDir}"
      '
    '';
    backupCleanupCommand = ''
      ${pkgs.bash}/bin/bash -c 'rm -rf "${vars.services.vaultwarden.backups.tmpDir}"'
    '';
  };
}
