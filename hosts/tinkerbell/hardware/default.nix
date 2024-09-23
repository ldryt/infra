{
  pkgs,
  lib,
  ...
}:
{
  imports = [ ./disko.nix ];

  services.fwupd.enable = true;

  # https://nixos.org/manual/nixos/unstable/index.html#sec-gpu-accel-vulkan
  hardware.opengl = {
    extraPackages = with pkgs; [
      amdvlk
    ];
    extraPackages32 = with pkgs; [
      driversi686Linux.amdvlk
    ];
  };

  boot = {
    loader.systemd-boot.enable = false;
    loader.efi.canTouchEfiVariables = true;
    lanzaboote = {
      enable = true;
      pkiBundle = "/etc/secureboot";
    };

    initrd = {
      systemd.enable = true;

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

    kernelModules = [
      "kvm-intel"
      "btusb"
    ];
    kernelParams = [ "quiet" ];
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
