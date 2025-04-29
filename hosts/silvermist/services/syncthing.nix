{ pkgs, config, ... }:
let
  dataDir = "/mnt/syncthing-data";
  configDir = "/var/lib/syncthing";
in
{
  # DURUBGK-S45UN27-6QQSHDA-7FWX3OS-4VCM4TD-NYMK6TV-JTEF742-VBTF7AZ
  sops.secrets."services/syncthing/key".owner = config.services.syncthing.user;
  sops.secrets."services/syncthing/cert".owner = config.services.syncthing.user;

  # config directory contains huge db
  environment.persistence.silvermist.directories = [ configDir ];

  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    inherit dataDir;
    inherit configDir;
    key = config.sops.secrets."services/syncthing/key".path;
    cert = config.sops.secrets."services/syncthing/cert".path;
    settings = {
      options = {
        localAnnounceEnabled = false;
      };
      devices = {
        "tinkerbell".id = "BRAQOO2-4MD5S4O-ORGTC3X-DEJDE3Q-YRK7V4E-VXXBR32-77PFW7P-G4Z6PAO";
        "domus".id = "PRSTEYD-BFS3F7N-6AS245G-SFISD7N-CDZPWIK-MN6U7PN-NPW64SW-UTKRWA5";
        "rosetta".id = "27GKCTR-KWK6GEH-RQSNP6R-MENWWMA-XPKMLIN-HAKD2FC-BC5BBKX-HGVV2QX";
      };
      folders = {
        "~/ldryt-notes" = {
          id = "ldryt-notes";
          ignorePerms = true;
          devices = [
            "tinkerbell"
            "domus"
            "rosetta"
          ];
        };
        "~/ldryt-vault" = {
          id = "ldryt-vault";
          ignorePerms = true;
          devices = [
            "tinkerbell"
            "domus"
            "rosetta"
          ];
        };
        "~/ldryt-documents" = {
          id = "ldryt-documents";
          ignorePerms = true;
          devices = [
            "tinkerbell"
            "domus"
            "rosetta"
          ];
        };
        "~/ldryt-pictures" = {
          id = "ldryt-pictures";
          devices = [
            "tinkerbell"
            "domus"
            "rosetta"
          ];
        };
      };
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
