{ config, ... }:
let
  devices = builtins.fromJSON (builtins.readFile ../../../syncthing-devices.json);
in
{
  sops.secrets."services/syncthing/key".owner = config.services.syncthing.user;
  sops.secrets."services/syncthing/cert".owner = config.services.syncthing.user;

  environment.persistence.luke.directories = [
    config.services.syncthing.dataDir
    config.services.syncthing.configDir
  ];

  services.syncthing = {
    enable = true;
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
      devices = builtins.removeAttrs devices [ "luke" ];
      folders =
        let
          folderCfg = {
            type = "receiveencrypted";
            ignorePerms = true;
            devices = [
              "tinkerbell"
              "domus"
              "rosetta"
              "silvermist"
              "sm-epita"
            ];
            versioning = {
              type = "simple";
              params.keep = "10";
            };
          };
          folderIds = [
            "ldryt-notes"
            "ldryt-vault"
            "ldryt-documents"
            "ldryt-pictures"
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
