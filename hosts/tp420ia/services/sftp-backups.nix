{ ... }:
let
  bckpDir = "/mnt/backups";
  bckpUser = "restic-backups";
in
{
  fileSystems."${bckpDir}" = {
    device = "/dev/disk/by-label/ldryt.dev\\x20-\\x20backups";
    fsType = "btrfs";
    options = [
      "defaults"
      "nofail"
    ];
  };

  users.groups."${bckpUser}" = { };
  users.users."${bckpUser}" = {
    isSystemUser = true;
    group = bckpUser;
    uid = 1442;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEqS0CzQnK6xfd/dch7Jm1QQCYZUuZyWgXZYImQ8OmiD colon@domus"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE6aepmmBNvNShGIp6gJM+TcXej/SIQokttO6ArjfTcv colon@silvermist"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGb0ZhjF+uNHovVeddQ7ZikoMl3DuQmajM3o6QYx3inm ldryt@tinkerbell"
    ];
  };

  services.openssh.extraConfig = ''
    Match User ${bckpUser}
        ForceCommand internal-sftp
        ChrootDirectory ${bckpDir}
  '';
}
