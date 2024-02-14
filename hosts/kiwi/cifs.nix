{ config, pkgs, ... }:
let hidden = import ../../secrets/obfuscated.nix;
in {
  environment.systemPackages = [ pkgs.cifs-utils ];
  fileSystems."/mnt/glouton" = {
    device = hidden.kiwi.smb.glouton.shareName;
    fsType = "cifs";
    options = [
      "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s,credentials=${
        config.sops.secrets."system/smb/glouton/credentials".path
      },uid=1000,gid=100,cache=loose,fsc"
    ];
  };
}
