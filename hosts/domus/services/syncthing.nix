{ config, ... }:
{
  sops.secrets."services/syncthing/key".owner = config.services.syncthing.user;
  sops.secrets."services/syncthing/cert".owner = config.services.syncthing.user;
  sops.secrets."services/syncthing/devices/luke/encryptionPassword".owner =
    config.services.syncthing.user;

  services.syncthing = {
    enable = true;
    dataDir = "/var/lib/syncthing/data";
    configDir = "/var/lib/syncthing/config";
    openDefaultPorts = true;
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
        builtins.readFile ../../../syncthing-devices.json
      )) [ "domus" ];
      folders =
        let
          folderCfg = {
            type = "receiveonly";
            devices = [
              "tinkerbell"
              "silvermist"
              "rosetta"
              {
                name = "luke";
                encryptionPasswordFile =
                  config.sops.secrets."services/syncthing/devices/luke/encryptionPassword".path;
              }
              "sm-epita"
            ];
            versioning = {
              type = "simple";
              params.keep = "10";
            };
          };
          folderIds = [
            "ldryt-notes"
            "ldryt-pictures"
            "ldryt-vault"
            "ldryt-documents"
          ];
        in
        builtins.listToAttrs (
          map (id: {
            name = "~/${id}";
            value = {
              inherit id;
            }
            // folderCfg;
          }) folderIds
        );
    };
  };
  systemd.services.syncthing.environment.STNODEFAULTFOLDER = "true";
}
