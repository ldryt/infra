{
  config,
  vars,
  lib,
  ...
}:
with lib;

let
  cfg = config.kiwi.backups;
in
{
  options.kiwi.backups = mkOption {
    type = types.attrsOf (
      types.submodule (
        { config, name, ... }:
        {
          options = {
            paths = mkOption {
              type = types.nullOr (types.listOf types.str);
              default = [ ];
            };
            backupPrepareCommand = mkOption {
              type = types.nullOr types.str;
              default = null;
            };
            backupCleanupCommand = mkOption {
              type = types.nullOr types.str;
              default = null;
            };
          };
        }
      )
    );
  };
  config = {
    sops.secrets."backups/restic/repositoryPass".owner = "root";
    sops.secrets."backups/restic/sshKey".owner = "root";
    services.restic.backups = mapAttrs' (
      name: conf:
      nameValuePair name {
        user = "root";
        backupPrepareCommand = conf.backupPrepareCommand;
        paths = conf.paths;
        initialize = true;
        repository = "sftp:${
          vars.sensitive.backups.user + "@" + vars.sensitive.backups.host
        }:restic-repo-${name}";
        extraOptions = [
          "sftp.command='ssh ${vars.sensitive.backups.user + "@" + vars.sensitive.backups.host} -p 23 -i ${
            config.sops.secrets."backups/restic/sshKey".path
          } -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -s sftp'"
        ];
        passwordFile = config.sops.secrets."backups/restic/repositoryPass".path;
        pruneOpts = [
          "--keep-daily 7"
          "--keep-weekly 8"
          "--keep-monthly 12"
          "--keep-yearly 100"
        ];
        timerConfig = {
          OnCalendar = "daily";
          RandomizedDelaySec = "6h";
          Persistent = true;
        };
      }
    ) cfg;
  };
}