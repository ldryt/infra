{ pkgs, config, ... }:
let
  dataDir = "/mnt/syncthing-data";
  configDir = "/var/lib/syncthing";
  devices = builtins.fromJSON (builtins.readFile ../../../syncthing-devices.json);
in
{
  sops.secrets."services/syncthing/key".owner = config.services.syncthing.user;
  sops.secrets."services/syncthing/cert".owner = config.services.syncthing.user;
  sops.secrets."services/syncthing/devices/luke/encryptionPassword".owner =
    config.services.syncthing.user;

  environment.persistence.silvermist.directories = [ configDir ];

  sops.secrets."backups/restic/repos/syncthing-silvermist/password" = { };
  ldryt-infra.backups.repos.syncthing-silvermist = {
    passwordFile = config.sops.secrets."backups/restic/repos/syncthing-silvermist/password".path;
    paths = [
      dataDir
      configDir
    ];
  };

  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    inherit dataDir;
    inherit configDir;
    key = config.sops.secrets."services/syncthing/key".path;
    cert = config.sops.secrets."services/syncthing/cert".path;
    settings = {
      options = {
        urAccepted = -1;
        crashReportingEnabled = false;
        natEnabled = false;
        localAnnounceEnabled = false;
      };
      devices = builtins.removeAttrs devices [ "silvermist" ];
      folders =
        let
          folderCfg = {
            type = "receiveonly";
            ignorePerms = true;
            devices = [
              "tinkerbell"
              "domus"
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

  sops.secrets."system/smb/glouton/syncthing-data/credentials" = { };
  environment.systemPackages = [ pkgs.cifs-utils ];
  fileSystems."${dataDir}" = {
    device = "//u391790-sub6.your-storagebox.de/u391790-sub6";
    fsType = "cifs";
    options = [
      "credentials=${config.sops.secrets."system/smb/glouton/syncthing-data/credentials".path}"

      "uid=${toString config.services.syncthing.user}"
      "forceuid"
      "gid=${toString config.services.syncthing.group}"
      "forcegid"
      "file_mode=0600"
      "dir_mode=0700"

      "vers=3.1.1"
      "sec=ntlmsspi"
      "seal"
      "hard"
      "mfsymlinks"

      "async"
      "noatime"
      "cache=loose"
      "actimeo=3600"
      "locallease"
      "rsize=4194304"
      "wsize=4194304"
      "fsc"

      "noauto"
      "x-systemd.automount"
      "x-systemd.idle-timeout=60"
      "x-systemd.mount-timeout=5s"
    ];
  };
}
