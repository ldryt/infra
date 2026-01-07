{
  config,
  lib,
  utils,
  ...
}:
with lib;

let
  cfg = config.ldryt-infra.backups;
in
{
  options.ldryt-infra.backups = {
    enableDefaultHosts = mkOption {
      type = types.bool;
      default = true;
    };

    hosts = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            enable = mkOption {
              type = types.bool;
              default = true;
            };

            url = mkOption {
              type = types.str;
            };

            sshKey = mkOption {
              type = types.str;
            };

            port = mkOption {
              type = types.port;
              default = 23;
            };
          };
        }
      );
      default = { };
    };

    repos = mkOption {
      type = types.attrsOf (
        types.submodule (
          { name, ... }:
          {
            options = {
              hosts = mkOption {
                type = types.listOf (types.enum (attrNames cfg.hosts));
                default = [
                  "glouton"
                  # "domus"
                ];
              };

              passwordFile = mkOption {
                type = types.str;
              };

              user = mkOption {
                type = types.str;
                default = "root";
              };

              paths = mkOption {
                type = types.listOf types.str;
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
                type = types.nullOr (types.attrsOf (utils.systemdUtils.unitOptions.unitOption));
                default = {
                  # everyday between 2AM and 4AM UTC
                  OnCalendar = "*-*-* 02:00:00 UTC";
                  RandomizedDelaySec = "2h";
                  Persistent = true;
                };
              };

              pruneOpts = mkOption {
                type = types.listOf types.str;
                default = [
                  "--keep-daily 7"
                  "--keep-weekly 8"
                  "--keep-monthly 12"
                  "--keep-yearly 100"
                ];
              };

              extraOptions = mkOption {
                type = types.listOf types.str;
                default = [ ];
              };
            };
          }
        )
      );
      default = { };
    };
  };

  config = {
    ldryt-infra.backups.hosts = mkIf cfg.enableDefaultHosts {
      glouton.url = mkDefault "u391790-sub3@u391790-sub3.your-storagebox.de";
      domus = {
        url = mkDefault "restic-backups@domus.ldryt.dev";
        port = mkDefault 22;
      };
    };

    services.restic.backups =
      let
        enabledHosts = filterAttrs (hostName: hostCfg: hostCfg.enable) cfg.hosts;
        all = concatLists (
          mapAttrsToList (
            repoName: repoCfg:
            map (hostName: {
              name = "${repoName}@${hostName}";
              value =
                let
                  hostCfg = enabledHosts.${hostName};
                in
                {
                  inherit (repoCfg)
                    user
                    paths
                    backupPrepareCommand
                    backupCleanupCommand
                    timerConfig
                    pruneOpts
                    passwordFile
                    ;
                  initialize = true;
                  repository = "sftp:${hostCfg.url}:restic-repo-${repoName}";
                  extraOptions = repoCfg.extraOptions ++ [
                    "sftp.command='ssh ${hostCfg.url} -p ${toString hostCfg.port} -i ${hostCfg.sshKey} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -s sftp'"
                  ];
                };
            }) (filter (host: hasAttr host enabledHosts) repoCfg.hosts)
          ) cfg.repos
        );
      in
      listToAttrs all;
  };
}
