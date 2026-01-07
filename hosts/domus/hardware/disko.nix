{ ... }:
{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "TODO";

      content = {
        type = "gpt";
        partitions = {
          FIRMWARE = {
            label = "FIRMWARE";
            priority = 1;
            type = "0700"; # Microsoft basic data
            attributes = [
              0 # Required Partition
            ];
            size = "1024M";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot/firmware";
              mountOptions = [
                "noatime"
                "noauto"
                "x-systemd.automount"
                "x-systemd.idle-timeout=1min"
              ];
            };
          };
          ESP = {
            label = "ESP";
            type = "EF00"; # EFI System Partition (ESP)
            attributes = [
              2 # Legacy BIOS Bootable, for U-Boot to find extlinux config
            ];
            size = "1024M";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [
                "noatime"
                "noauto"
                "x-systemd.automount"
                "x-systemd.idle-timeout=1min"
                "umask=0077"
              ];
            };
          };
          swap = {
            type = "8200"; # Linux swap
            size = "2G";
            content = {
              type = "swap";
              discardPolicy = "both";
            };
          };
          nix = {
            type = "8305"; # Linux ARM64 root (/)
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/nix";
            };
          };
        };
      };
    };
    nodev."/" = {
      fsType = "tmpfs";
      mountOptions = [
        "size=512M"
        "defaults"
        "mode=755"
      ];
    };
  };
}
