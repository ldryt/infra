{ lib, inputs, ... }:
{
  imports = [
    inputs.nixos-raspberrypi.nixosModules.trusted-nix-caches
    inputs.nixos-raspberrypi.nixosModules.raspberry-pi-4.base
  ];

  services.udev.extraRules = ''
    # https://github.com/nvmd/nixos-raspberrypi-demo/blob/2847963e7555fc412c1d0f37bb48c761e78f350d/flake.nix#L154-L160
    # Ignore partitions with "Required Partition" GPT partition attribute
    # On our RPis this is firmware (/boot/firmware) partition
    # 
    ENV{ID_PART_ENTRY_SCHEME}=="gpt", \
      ENV{ID_PART_ENTRY_FLAGS}=="0x1", \
      ENV{UDISKS_IGNORE}="1"
  '';

  services.journald.console = "/dev/tty1";

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

  # Some modules are included by default, but our rpi kernel doesn't
  # include all.
  # This overlay ignores missing modules errors
  # https://github.com/NixOS/nixpkgs/issues/126755#issuecomment-869149243
  nixpkgs.overlays = [
    (final: super: {
      makeModulesClosure = x: super.makeModulesClosure (x // { allowMissing = true; });
    })
  ];
}
