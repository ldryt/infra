{
  config,
  lib,
  pkgs,
  ...
}:
let
  mount =
    name:
    {
      user ? "root",
      group ? "users",
      umask ? "0077",
      readOnly ? false,
      mountPoint ? "/mnt/${name}",
    }:
    lib.nameValuePair mountPoint {
      device = "${name}:";
      fsType = "rclone";
      options = [
        "nodev"
        "nofail"
        "_netdev"
        "x-systemd.automount"
        "allow_other"
        "default_permissions"
        "args2env"
        "config=${config.sops.secrets."system/rclone/rclone.conf".path}"
        "uid=${toString config.users.users.${user}.uid}"
        "gid=${toString config.users.groups.${group}.gid}"
        "umask=${umask}"
        "cache-dir=/var/lib/rclone/cache/${name}"
        "vfs-cache-mode=full"
        "vfs-cache-max-size=20G"
        "vfs-cache-min-free-space=5G"
        "vfs-cache-max-age=168h"
      ]
      ++ lib.optional readOnly "ro";
    };
in
{
  options.ldryt-infra.rclone.mounts = lib.mkOption {
    type = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
    default = { };
  };

  config = {
    ldryt-infra.persist.directories = [ "/var/lib/rclone" ];
    environment.systemPackages = [ pkgs.rclone ];
    sops.secrets."system/rclone/rclone.conf" = { };
    fileSystems = lib.mapAttrs' mount config.ldryt-infra.rclone.mounts;
  };
}
