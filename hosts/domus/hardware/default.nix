{ lib, ... }:
{
  imports = [
    ./uart.nix
  ];

  # Remove zfs:
  boot.supportedFilesystems.zfs = lib.mkForce false;

  boot.kernelParams = lib.mkForce [ ];

  # Some modules are included by default, but our rpi kernel doesn't
  # include all.
  # This overlay ignores missing modules errors
  # https://github.com/NixOS/nixpkgs/issues/126755#issuecomment-869149243
  nixpkgs.overlays = [
    (final: super: {
      makeModulesClosure = x: super.makeModulesClosure (x // { allowMissing = true; });
    })
  ];

  # Note: hardware options imported from https://github.com/NixOS/nixos-hardware/blob/e81fd167b33121269149c57806599045fd33eeed/flake.nix#L323
  # A lot of device tree quirks applied from there.
  hardware.raspberry-pi."4" = {
    # Fixes https://github.com/NixOS/nixpkgs/issues/125354
    apply-overlays-dtmerge.enable = true;
  };

  hardware.deviceTree = {
    enable = true;
    filter = "bcm2711-rpi-4*.dtb";
  };
}
