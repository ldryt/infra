{ pkgs, config, ... }:
let
  common = import ./default.nix;
in
{
  systemd.services.immich-server.after = [
    "mnt-immich.mount"
    "mnt-gdrive\\x2dphotos\\x2d2004\\x2d2017.mount"
  ];

  environment.systemPackages = [
    pkgs.cifs-utils
    pkgs.rclone
  ];

  sops.secrets."system/smb/glouton/immich-library/credentials" = { };
  fileSystems."${common.dataDir}" = {
    device = "//u391790-sub1.your-storagebox.de/u391790-sub1";
    fsType = "cifs";
    options = [
      "credentials=${config.sops.secrets."system/smb/glouton/immich-library/credentials".path}"

      "uid=${toString config.services.immich.user}"
      "forceuid"
      "gid=${toString config.services.immich.group}"
      "forcegid"
      "file_mode=0770"
      "dir_mode=0770"

      "vers=3.1.1"
      "sec=ntlmsspi"
      "seal"

      "async"
      "noatime"
      "rsize=4194304"
      "wsize=4194304"
      "fsc"

      "noauto"
      "x-systemd.automount"
      "x-systemd.idle-timeout=600s"
      "x-systemd.mount-timeout=15s"
    ];
  };

  sops.secrets."system/rclone/gdrive-photos-2004-2017-crypted/rclone.conf" = { };
  fileSystems."${common.gdriveArchiveMount}" = {
    device = "gdrive-photos-2004-2017-crypted:/";
    fsType = "rclone";
    options = [
      "nodev"
      "nofail"

      "allow_other"
      "default_permissions"
      "uid=${toString config.services.immich.user}"
      "gid=${toString config.services.immich.group}"
      "umask=007"

      "cache-dir=/var/cache/rclone-vfs-1"
      "vfs-cache-mode=full"
      "vfs-cache-min-free-space=5G"
      "vfs-cache-max-age=6w"

      "log-level=DEBUG"

      "args2env"
      "config=${config.sops.secrets."system/rclone/gdrive-photos-2004-2017-crypted/rclone.conf".path}"
    ];
  };
}
