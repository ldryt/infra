{ lib, pkgs, ... }:
{
  virtualisation.libvirtd = {
    enable = true;
    qemu.runAsRoot = false;
    onBoot = "ignore";
    onShutdown = "shutdown";
  };

  users.users.ldryt.extraGroups = [ "libvirtd" ];

  environment.systemPackages = with pkgs; [
    libvirt # virsh
    virt-manager # includes virt-install
  ];
  environment.sessionVariables.LIBVIRT_DEFAULT_URI = lib.mkDefault "qemu:///system";

  ldryt-infra.persist.directories = [ "/var/lib/libvirt" ];
}
