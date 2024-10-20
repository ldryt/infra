{ pkgs, ... }:
{
  nixpkgs.hostPlatform = "aarch64-linux";
  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_rpi3;
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
    kernelParams = [
      "console=ttyS0,115200n8"
      "console=tty0"
    ];
  };

  # fix the following error :
  # modprobe: FATAL: Module ahci not found in directory
  # https://github.com/NixOS/nixpkgs/issues/154163#issuecomment-1350599022
  nixpkgs.overlays = [
    (_final: super: {
      makeModulesClosure = x: super.makeModulesClosure (x // { allowMissing = true; });
    })
  ];
}
