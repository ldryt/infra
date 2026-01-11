{
  config,
  pkgs,
  lib,
  modulesPath,
  ...
}:
{
  imports = [ "${modulesPath}/installer/sd-card/sd-image-aarch64.nix" ];

  sdImage = {
    compressImage = false;
    rootVolumeLabel = "NIXOS_PERSIST";
  };

  fileSystems = {
    "/persist" = {
      device = "/dev/disk/by-label/${config.sdImage.rootVolumeLabel}";
      fsType = "ext4";
      neededForBoot = true;
      options = [ "noatime" ];
    };
    "/nix" = {
      device = "/persist/nix";
      fsType = "none";
      options = [ "bind" ];
      neededForBoot = true;
    };
    "/boot" = {
      device = "/persist/boot";
      fsType = "none";
      options = [ "bind" ];
    };
    "/" = lib.mkForce {
      device = "none";
      fsType = "tmpfs";
      options = [
        "defaults"
        "size=256M"
        "mode=755"
      ];
    };
  };
  swapDevices = [
    {
      device = "/persist/swapfile";
      size = 1024;
    }
  ];

  # From https://github.com/NixOS/nixpkgs/blob/f4d595514856b921dd31c90cc02eb8d917a37a3f/nixos/modules/installer/sd-card/sd-image.nix#L346
  # We need to overwrite it because upstream tries to resize "/", which is tmpfs
  boot.postBootCommands =
    let
      expandOnBoot = lib.optionalString config.sdImage.expandOnBoot ''
        # Figure out device names for the boot device and root filesystem.
        rootPart=$(${pkgs.util-linux}/bin/findmnt -n -o SOURCE /persist)
        bootDevice=$(lsblk -npo PKNAME $rootPart)
        partNum=$(lsblk -npo MAJ:MIN $rootPart | ${pkgs.gawk}/bin/awk -F: '{print $2}')

        # Resize the root partition and the filesystem to fit the disk
        echo ",+," | sfdisk -N$partNum --no-reread $bootDevice
        ${pkgs.parted}/bin/partprobe
        ${pkgs.e2fsprogs}/bin/resize2fs $rootPart
      '';
      nixPathRegistrationFile = config.sdImage.nixPathRegistrationFile;
    in
    ''
      # On the first boot do some maintenance tasks
      if [ -f ${nixPathRegistrationFile} ]; then
        set -euo pipefail
        set -x

        ${expandOnBoot}

        # Register the contents of the initial Nix store
        ${config.nix.package.out}/bin/nix-store --load-db < ${nixPathRegistrationFile}

        # nixos-rebuild also requires a "system" profile and an /etc/NIXOS tag.
        touch /etc/NIXOS
        ${config.nix.package.out}/bin/nix-env -p /nix/var/nix/profiles/system --set /run/current-system

        # Prevents this from running on later boots.
        rm -f ${nixPathRegistrationFile}
      fi
    '';
}
