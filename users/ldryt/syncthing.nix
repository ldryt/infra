{ config, ... }:
{
  # BRAQOO2-4MD5S4O-ORGTC3X-DEJDE3Q-YRK7V4E-VXXBR32-77PFW7P-G4Z6PAO
  sops.secrets."services/syncthing/key" = { };
  sops.secrets."services/syncthing/cert" = { };

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
      )) [ "tinkerbell" ];
      folders =
        let
          folderCfg = {
            devices = [
              "silvermist"
              "domus"
              "rosetta"
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
          } // folderCfg;
          "~/Sync/Notes" = {
            id = "ldryt-notes";
          } // folderCfg;
          "~/Documents/Sync" = {
            id = "ldryt-documents";
          } // folderCfg;
          "~/Pictures" = {
            id = "ldryt-pictures";
          } // folderCfg;
        };
    };
  };
}
