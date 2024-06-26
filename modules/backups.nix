{
  config,
  lib,
  utils,
  ...
}:
with lib;

let
  cfg = config.ldryt-infra.backups;
  inherit (utils.systemdUtils.unitOptions) unitOption;

  storageBox = "u391790-sub3@u391790-sub3.your-storagebox.de";
in
{
  options.ldryt-infra.backups = mkOption {
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
            timerConfig = mkOption {
              type = types.nullOr (types.attrsOf unitOption);
              default = {
                OnCalendar = "daily";
                RandomizedDelaySec = "2h";
                Persistent = true;
              };
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
        repository = "sftp:${storageBox}:restic-repo-${name}";
        extraOptions = [
          "sftp.command='ssh ${storageBox} -p 23 -i ${
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
        timerConfig = conf.timerConfig;
      }
    ) cfg;
  };
}
