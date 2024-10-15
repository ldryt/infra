{
  pkgs,
  lib,
  modulesPath,
  ...
}:
{
  # Note: module "framework-13-7040-amd" from https://github.com/NixOS/nixos-hardware is imported in flake

  imports = [
    ./disko.nix
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  fileSystems."/swap".neededForBoot = true;

  fileSystems."/nix".neededForBoot = true;

  services.fwupd.enable = true;

  services.fprintd.enable = true;

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # https://nixos.org/manual/nixos/unstable/index.html#sec-gpu-accel-vulkan
  hardware.graphics = {
    extraPackages = with pkgs; [ amdvlk ];
    extraPackages32 = with pkgs; [ driversi686Linux.amdvlk ];
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
    kernelModules = [ "kvm-amd" ];
    kernelParams = [ "quiet" ];

    loader.efi.canTouchEfiVariables = true;

    # Lanzaboote currently replaces the systemd-boot module.
    loader.systemd-boot.enable = false;
    initrd.systemd.enable = true;
    lanzaboote = {
      enable = true;
      pkiBundle = "/etc/secureboot";
    };
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
