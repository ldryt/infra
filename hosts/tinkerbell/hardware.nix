{
  config,
  lib,
  modulesPath,
  ...
}:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot = {
    loader.systemd-boot.enable = false;
    loader.efi.canTouchEfiVariables = true;
    lanzaboote = {
      enable = true;
      pkiBundle = "/etc/secureboot";
    };

    initrd = {
      luks.devices = {
        luksroot = {
          device = "/dev/disk/by-uuid/2a5e5a55-e8ba-49f4-8e78-9f0eaacc2dca";
          preLVM = true;
          allowDiscards = true;
        };
      };

      availableKernelModules = [
        "xhci_pci"
        "ahci"
        "nvme"
        "usb_storage"
        "sd_mod"
        "rtsx_pci_sdmmc"
      ];
      kernelModules = [ "dm-snapshot" ];
    };

    kernelModules = [ "kvm-intel" "btusb" ];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/f5e59624-6316-42b2-a3d1-5f83f576333e";
    fsType = "btrfs";
    options = [
      "compress=zstd"
      "subvol=root"
    ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/f5e59624-6316-42b2-a3d1-5f83f576333e";
    fsType = "btrfs";
    options = [
      "compress=zstd"
      "subvol=home"
    ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/f5e59624-6316-42b2-a3d1-5f83f576333e";
    fsType = "btrfs";
    options = [
      "compress=zstd"
      "noatime"
      "subvol=nix"
    ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/AE23-3471";
    fsType = "vfat";
  };

  swapDevices = [ { device = "/dev/disk/by-uuid/b773adaa-3466-4383-bd8e-170d670f41b6"; } ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = config.hardware.enableRedistributableFirmware;
}
