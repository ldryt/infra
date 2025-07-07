{
  config,
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    ./power.nix
    ./disko.nix

    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  fileSystems."/swap".neededForBoot = true;
  fileSystems."/nix".neededForBoot = true;

  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = config.hardware.enableRedistributableFirmware;

  boot = {
    initrd.availableKernelModules = [
      "nvme"
      "xhci_pci"
      "ahci"
      "usbhid"
      "usb_storage"
      "sr_mod"
    ];
    kernelModules = [
      "kvm-amd"
    ];

    loader.efi.canTouchEfiVariables = true;

    loader.systemd-boot = {
      configurationLimit = 20;
      consoleMode = "auto";
      memtest86 = {
        enable = true;
        sortKey = "z_memtest86";
      };
    };

    # Lanzaboote currently replaces the systemd-boot module
    # Options from 'config.boot.loader.systemd-boot' are inherited
    #
    # To register password in TPM:
    # > sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+2+7+12 --wipe-slot=tpm2 /dev/nvme0n1p2
    loader.systemd-boot.enable = lib.mkForce false;
    initrd.systemd.enable = true;
    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
