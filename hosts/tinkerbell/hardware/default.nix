{
  inputs,
  pkgs,
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

  # Note: module "framework-13-7040-amd" from https://github.com/NixOS/nixos-hardware is imported in flake
  hardware.framework = {
    enableKmod = true;
    laptop13.audioEnhancement = {
      enable = true;
      rawDeviceName = "alsa_output.pci-0000_c1_00.6.analog-stereo";
      hideRawDevice = false;
    };
  };

  fileSystems."/swap".neededForBoot = true;
  boot.kernel.sysctl."vm.swappiness" = 15;

  fileSystems."/nix".neededForBoot = true;

  boot.binfmt = {
    emulatedSystems = [ "aarch64-linux" ];
    preferStaticEmulators = true;
  };

  services.fwupd.enable = true;

  services.fprintd.enable = false;

  services.xserver.xkb = {
    layout = "qwerty-fr,us,fr";
    extraLayouts.qwerty-fr = {
      description = "US layout with French accents";
      languages = [ "eng" ];
      symbolsFile = "${pkgs.qwerty-fr}/share/X11/xkb/symbols/us_qwerty-fr";
    };
  };

  services.udev.extraRules = ''
    # Disable Logitech G703 autosuspend (avoiding 1s wake-up delay)
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="046d", ATTR{idProduct}=="c539", ATTR{power/autosuspend}="-1"
  '';

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  security.rtkit.enable = true;

  environment.systemPackages = [
    pkgs.fw-ectool
    pkgs.framework-tool
  ];

  nixpkgs.overlays = [ inputs.mac-style-plymouth.overlays.default ];
  boot = {
    plymouth = {
      enable = true;
      theme = "mac-style";
      themePackages = [
        (pkgs.mac-style-plymouth.overrideAttrs (oldAttrs: {
          installPhase = oldAttrs.installPhase + ''
            rm "$out/share/plymouth/themes/mac-style/images/header-image.png"
          '';
        }))
      ];
    };

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

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
