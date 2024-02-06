{ lib, modulesPath, ... }: {
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
  boot.loader.grub.device = "/dev/sda";
  boot.initrd.availableKernelModules =
    [ "ata_piix" "uhci_hcd" "xen_blkfront" "vmw_pvscsi" ];
  boot.initrd.kernelModules = [ "nvme" ];
  fileSystems."/" = {
    device = "/dev/sda1";
    fsType = "ext4";
  };

  # https://danwin1210.de/github-ipv6-proxy.php
  networking.extraHosts = ''
    2a01:4f8:c010:d56::2 github.com
    2a01:4f8:c010:d56::3 api.github.com
    2a01:4f8:c010:d56::4 codeload.github.com
    2a01:4f8:c010:d56::5 objects.githubusercontent.com
    2a01:4f8:c010:d56::6 ghcr.io
    2a01:4f8:c010:d56::7 pkg.github.com npm.pkg.github.com maven.pkg.github.com nuget.pkg.github.com rubygems.pkg.github.com
  '';

  # https://nixos.wiki/wiki/Install_NixOS_on_Hetzner_Cloud
  systemd.network.enable = true;
  systemd.network.networks."10-wan" = {
    matchConfig.Name = "ens3";
    networkConfig.DHCP = "ipv4";
    address = [ "2a01:4f8:1c1e:dd78::1/64" ];
    routes = [{ routeConfig.Gateway = "fe80::1"; }];
  };

  networking.useDHCP = false;
}
