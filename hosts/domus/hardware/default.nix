{
  lib,
  modulesPath,
  pkgs,
  ...
}:
{
  imports = [
    ./disko.nix

    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  fileSystems."/swap".neededForBoot = true;
  boot.kernel.sysctl."vm.swappiness" = 15;

  # USB-C hub: UAS hangs and unreliable power management.
  boot.kernelParams = [
    "usb-storage.quirks=7825:a2a4:u,152d:0578:u"
    "usbcore.autosuspend=-1"
  ];

  # HGST APM level 1 => drive goes brrrr.
  systemd.services.hgst-stable-apm = {
    description = "Disable aggressive power management on the HGST media disk";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecCondition = "${pkgs.coreutils}/bin/test -b /dev/disk/by-id/ata-HGST_HTS541010A9E680_JD100ACH198WYK";
      ExecStart = "${pkgs.hdparm}/bin/hdparm -B 254 /dev/disk/by-id/ata-HGST_HTS541010A9E680_JD100ACH198WYK";
    };
  };

  fileSystems."/nix".neededForBoot = true;

  boot.binfmt = {
    emulatedSystems = [ "aarch64-linux" ];
    preferStaticEmulators = true;
  };

  boot = {
    initrd.availableKernelModules = [
      "nvme"
      "xhci_pci"
      "uas"
      "usb_storage"
    ];
    kernelModules = [
      "kvm-amd"
    ];

    loader.efi.canTouchEfiVariables = true;

    loader.timeout = 10;
    loader.systemd-boot = {
      configurationLimit = 20;
      consoleMode = "auto";
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
