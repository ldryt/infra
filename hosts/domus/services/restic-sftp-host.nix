{ ... }:
let
  bckpDir = "/mnt/restic-backups";
  bckpUser = "restic-backups";
in
{
  fileSystems."${bckpDir}" = {
    device = "/dev/disk/by-uuid/9b37793d-5610-4f94-a421-cbe6898df45f";
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
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE6aepmmBNvNShGIp6gJM+TcXej/SIQokttO6ArjfTcv colon@silvermist"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGb0ZhjF+uNHovVeddQ7ZikoMl3DuQmajM3o6QYx3inm ldryt@tinkerbell"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIK/FQMGmX4ufehnHBclgRxiUK0uVd6fGFHxP8MiQmKo colon@luke"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMaNQCMEUxGla8VAR3X0ihEcZ5glaFWlQQMveDrQ9mQR colon@printer"
    ];
  };

  services.openssh.extraConfig = ''
    Match User ${bckpUser}
        ForceCommand internal-sftp
        ChrootDirectory ${bckpDir}
  '';
}
