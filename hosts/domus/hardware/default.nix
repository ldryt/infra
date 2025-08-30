{ pkgs, lib, ... }:
{
  # Remove zfs:
  boot.supportedFilesystems.zfs = lib.mkForce false;

  boot.kernelParams = [
    "console=ttyS0,115200n8"
    "console=tty0"
  ];

  boot.loader = {
    grub.enable = false;
    generic-extlinux-compatible.enable = true;
  };

  boot.kernelPackages = pkgs.linuxKernel.packages.linux_rpi3;

  # Some modules are included by default, but our rpi kernel doesn't
  # include all.
  # This overlay ignores missing modules errors
  # https://github.com/NixOS/nixpkgs/issues/126755#issuecomment-869149243
  nixpkgs.overlays = [
    (final: super: {
      makeModulesClosure = x: super.makeModulesClosure (x // { allowMissing = true; });
    })
  ];

  hardware = {
    enableRedistributableFirmware = lib.mkForce false;
    firmware = [ pkgs.raspberrypiWirelessFirmware ];
  };
}
