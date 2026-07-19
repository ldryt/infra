{ modulesPath, ... }:
{
  imports = [
    ./disko.nix

    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  fileSystems."/nix".neededForBoot = true;

  boot = {
    initrd.availableKernelModules = [
      "xhci_pci"
      "virtio_pci"
      "virtio_blk"
      "virtio_scsi"
      "ahci"
      "nvme"
      "sr_mod"
    ];

    loader.grub = {
      efiSupport = true;
      efiInstallAsRemovable = true;
    };
  };

  nixpkgs.hostPlatform = "x86_64-linux";
}
