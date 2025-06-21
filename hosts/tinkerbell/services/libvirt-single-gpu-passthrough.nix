# https://olai.dev/blog/nvidia-vm-passthrough/

{ lib, pkgs, ... }:
let
  user = "ldryt";
  gpuPciAddress = "pci_0000_c1_00_0";
in
{
  boot = {
    kernelParams = [
      "amd_iommu=on"
      "iommu=pt"
    ];

    kernelModules = [
      "kvm-amd"
      "vfio_pci"
      "vfio_iommu_type1"
      "vfio"
    ];
  };

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      runAsRoot = false;
      ovmf.enable = true;
    };
    onBoot = "ignore";
    onShutdown = "shutdown";
    hooks.qemu = {
      "passthrough-prepare-begin.sh" = lib.getExe (
        pkgs.writeShellApplication {
          name = "libvirtd-qemu-passthrough-prepare-begin.sh";
          runtimeInputs = with pkgs; [
            libvirt
            systemd
            kmod
          ];
          text = ''
            set -xeu

            [[ "$1" != *-pt || "$2" != "prepare" || "$3" != "begin" ]] && exit

            # Stop display manager
            systemctl stop display-manager

            # Unbind VTconsoles: might not be needed
            echo 0 > /sys/class/vtconsole/vtcon0/bind
            echo 0 > /sys/class/vtconsole/vtcon1/bind

            # Unbind EFI Framebuffer
            echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind

            # Unload AMD kernel module
            modprobe -r amdgpu

            # Detach GPU from host
            virsh nodedev-detach ${gpuPciAddress}

            # Load vfio module
            modprobe vfio-pci
          '';
        }
      );
      "passthrough-release-end.sh" = lib.getExe (
        pkgs.writeShellApplication {
          name = "libvirtd-qemu-passthrough-release-end.sh";
          runtimeInputs = with pkgs; [
            libvirt
            systemd
            kmod
          ];
          text = ''
            set -xeu

            [[ "$1" != *-pt || "$2" != "release" || "$3" != "end" ]] && exit

            # Attach GPU to host
            virsh nodedev-reattach ${gpuPciAddress}

            # Unload vfio module
            modprobe -r vfio-pci

            # Load AMD kernel module
            modprobe amdgpu

            # Rebind framebuffer to host
            echo "efi-framebuffer.0" > /sys/bus/platform/drivers/efi-framebuffer/bind

            # Bind VTconsoles: might not be needed
            echo 1 > /sys/class/vtconsole/vtcon0/bind
            echo 1 > /sys/class/vtconsole/vtcon1/bind

            # Restart Display Manager
            systemctl start display-manager
          '';
        }
      );
    };
  };

  users.users.${user}.extraGroups = [
    "libvirtd"
    "qemu-libvirtd"
  ];

  environment.systemPackages = with pkgs; [
    virt-manager
    looking-glass-client
  ];

  systemd.tmpfiles.rules = [
    "f /dev/shm/looking-glass 0660 ${user} qemu-libvirtd -"
  ];

  environment.persistence.tinkerbell.directories = [ "/var/lib/libvirt" ];
}
