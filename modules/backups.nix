{
  config,
  lib,
  utils,
  pkgs,
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

            type = mkOption {
              type = types.enum [
                "sftp"
                "rclone"
              ];
              default = "sftp";
            };

            url = mkOption {
              type = types.str;
              description = "SFTP Only";
              default = "";
            };

            rcloneRemote = mkOption {
              type = types.str;
              default = "";
            };

            rcloneConfigFile = mkOption {
              type = types.nullOr types.path;
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
        types.submodule (
          { name, ... }:
          {
            options = {
              hosts = mkOption {
                type = types.listOf (types.enum (attrNames cfg.hosts));
                default = [
                  "glouton"
                  # "domus"
                  "gdrive"
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
                  "--keep-weekly 8"
                  "--keep-monthly 12"
                  "--keep-yearly 100"
                  "--group-by host"
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
    environment.systemPackages = mkIf (any (h: h.type == "rclone") (attrValues cfg.hosts)) [
      pkgs.rclone
    ];

    ldryt-infra.backups.hosts = mkIf cfg.enableDefaultHosts {
      glouton.url = mkDefault "u391790-sub3@u391790-sub3.your-storagebox.de";
      domus = {
        url = mkDefault "restic-backups@domus.ldryt.dev";
        port = mkDefault 22;
      };
      gdrive = {
        type = mkDefault "rclone";
        rcloneRemote = mkDefault "gdrive";
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
                  isRclone = hostCfg.type == "rclone";
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
                  inherit (hostCfg)
                    rcloneConfigFile
                    ;
                  initialize = true;

                  repository =
                    if isRclone then
                      "rclone:${hostCfg.rcloneRemote}:restic-repo-${repoName}"
                    else
                      "sftp:${hostCfg.url}:restic-repo-${repoName}";

                  extraOptions =
                    repoCfg.extraOptions
                    ++ (optionals (!isRclone) [
                      "sftp.command='ssh ${hostCfg.url} -p ${toString hostCfg.port} -i ${hostCfg.sshKey} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -s sftp'"
                    ]);
                };
            }) (filter (host: hasAttr host enabledHosts) repoCfg.hosts)
          ) cfg.repos
        );
      in
      listToAttrs all;
  };
}
