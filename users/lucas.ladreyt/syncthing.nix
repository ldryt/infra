{ config, ... }:
{
  sops.secrets."services/syncthing/key" = { };
  sops.secrets."services/syncthing/cert" = { };
  sops.secrets."services/syncthing/devices/luke/encryptionPassword" = { };

  # workaround to avoid syncthing-init.service dependency failure on boot
  systemd.user.services."syncthing".Unit.After = [ "sops-nix.service" ];

  services.syncthing = {
    enable = true;
    key = config.sops.secrets."services/syncthing/key".path;
    cert = config.sops.secrets."services/syncthing/cert".path;
    settings = {
      options = {
        urAccepted = -1;
        crashReportingEnabled = false;
        natEnabled = false;
        localAnnounceEnabled = false;
      };
      devices = builtins.removeAttrs (builtins.fromJSON (
        builtins.readFile ../../syncthing-devices.json
      )) [ "sm-epita" ];
      folders =
        let
          folderCfg = {
            devices = [
              "tinkerbell"
              "silvermist"
              "domus"
              "rosetta"
              {
                name = "luke";
                encryptionPasswordFile =
                  config.sops.secrets."services/syncthing/devices/luke/encryptionPassword".path;
              }
            ];
            versioning = {
              type = "simple";
              params.keep = "10";
            };
          };
        in
        {
          "~/Sync/Vault" = {
            id = "ldryt-vault";
          }
          // folderCfg;
          "~/Sync/Notes" = {
            id = "ldryt-notes";
          }
          // folderCfg;
          "~/Documents/Sync" = {
            id = "ldryt-documents";
          }
          // folderCfg;
          "~/Pictures/Sync" = {
            id = "ldryt-pictures";
          }
          // folderCfg;
        };
    };
  };
}
