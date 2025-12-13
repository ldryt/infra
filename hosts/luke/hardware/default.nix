{
  modulesPath,
  ...
}:
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
      "ahci"
      "usbhid"
      "usb_storage"
      "sr_mod"
    ];

    loader.grub = {
      # no need to set devices, disko will add all devices that have a EF02 partition to the list already
      # devices = [ ];
      efiSupport = true;
      efiInstallAsRemovable = true;
    };
  };

  nixpkgs.hostPlatform = "aarch64-linux";
}
