{ config, pkgs, ... }:
let hidden = import ../../secrets/obfuscated.nix;
in {
  environment.systemPackages = [ pkgs.cifs-utils ];
  fileSystems."/mnt/glouton/minio-buckets" = {
    device = hidden.kiwi.smb.glouton.minio-buckets.shareName;
    fsType = "cifs";
    options = [
      "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s,credentials=${
        config.sops.secrets."system/smb/glouton/minio-buckets/credentials".path
      },uid=1000,cache=loose,fsc,sfu"
    ];
  };
}
