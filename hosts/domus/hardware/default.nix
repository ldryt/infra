{
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    ./disko.nix

    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  fileSystems."/swap".neededForBoot = true;
  boot.kernel.sysctl."vm.swappiness" = 15;

  fileSystems."/nix".neededForBoot = true;

  boot.binfmt = {
    emulatedSystems = [ "aarch64-linux" ];
    preferStaticEmulators = true;
  };

  boot = {
    initrd.availableKernelModules = [
      "nvme"
      "xhci_pci"
      "thunderbolt"
      "uas"
      "usb_storage"
      "sd_mod"
    ];
    kernelModules = [
      "kvm-amd"
    ];
    kernelParams = [
      "clocksource=tsc"
      "tsc=reliable"
    ];

    loader.efi.canTouchEfiVariables = true;

    loader.timeout = 1;
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
    loader.systemd-boot.enable = false;
    initrd.systemd.enable = true;
    lanzaboote = {
      enable = true;
      pkiBundle = "/etc/secureboot";
    };
  };

  ldryt-infra.persist.directories = [
    "/var/lib/fprint"
    "/var/lib/bluetooth"
    "/etc/secureboot"
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
