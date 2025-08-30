{ config, ... }:
{
  # PRSTEYD-BFS3F7N-6AS245G-SFISD7N-CDZPWIK-MN6U7PN-NPW64SW-UTKRWA5
  sops.secrets."services/syncthing/key".owner = config.services.syncthing.user;
  sops.secrets."services/syncthing/cert".owner = config.services.syncthing.user;

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
