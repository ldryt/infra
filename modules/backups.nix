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
              default = "";
            };

            rcloneRemote = mkOption {
              type = types.nullOr types.str;
              default = null;
            };

            sshKey = mkOption {
              type = types.str;
              default = "";
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
        types.submodule {
          options = {
            hosts = mkOption {
              type = types.listOf (types.enum (attrNames cfg.hosts));
              default = [
                "glouton"
                "domus"
                "onedrive"
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

            exclude = mkOption {
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
                # everyday between 4AM and 8AM (system time)
                OnCalendar = "*-*-* 04:00:00";
                RandomizedDelaySec = "4h";
                Persistent = true;
              };
            };

            pruneOpts = mkOption {
              type = types.listOf types.str;
              default = [
                "--keep-daily 7"
                "--keep-weekly 4"
                "--keep-monthly 3"
                "--keep-yearly 2"
                "--group-by host"
              ];
            };

            extraOptions = mkOption {
              type = types.listOf types.str;
              default = [ ];
            };
          };
        }
      );
      default = { };
    };
  };

  config = {
    ldryt-infra.backups.hosts = {
      glouton.url = "u391790-sub3@u391790-sub3.your-storagebox.de";
      domus = {
        url = "restic-backups@domus.ldryt.dev";
        port = 22;
      };
      onedrive.rcloneRemote = "onedrive";
    };

    services.restic.backups = listToAttrs (
      concatLists (
        mapAttrsToList (
          repoName: repo:
          map (
            hostName:
            let
              host = cfg.hosts.${hostName};
              isRclone = host.rcloneRemote != null;
            in
            nameValuePair "${repoName}@${hostName}" (
              (removeAttrs repo [ "hosts" ])
              // {
                rcloneConfigFile = if isRclone then config.sops.secrets."system/rclone/rclone.conf".path else null;
                initialize = true;
                repository =
                  if isRclone then
                    "rclone:${host.rcloneRemote}:restic-repo-${repoName}"
                  else
                    "sftp:${host.url}:restic-repo-${repoName}";
                extraOptions =
                  repo.extraOptions
                  ++
                    optional (!isRclone)
                      "sftp.command='ssh ${host.url} -p ${toString host.port} -i ${host.sshKey} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -s sftp'";
              }
            )
          ) (filter (name: cfg.hosts.${name}.enable or false) repo.hosts)
        ) cfg.repos
      )
    );

    systemd.services = mapAttrs' (
      name: _:
      nameValuePair "restic-backups-${name}" {
        serviceConfig = {
          Restart = "on-failure";
          RestartSec = "5min";
        };
      }
    ) config.services.restic.backups;
  };
}
