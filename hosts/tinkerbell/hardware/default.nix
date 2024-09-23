{
  pkgs,
  lib,
  ...
}:
{
  # Note: module "framework-13-7040-amd" from https://github.com/NixOS/nixos-hardware is imported in flake

  imports = [ ./disko.nix ];

  services.fwupd.enable = true;

  # https://nixos.org/manual/nixos/unstable/index.html#sec-gpu-accel-vulkan
  hardware.graphics = {
    extraPackages = with pkgs; [
      amdvlk
    ];
    extraPackages32 = with pkgs; [
      driversi686Linux.amdvlk
    ];
  };

  boot = {
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
