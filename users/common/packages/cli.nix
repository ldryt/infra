{ pkgs, ... }:
{
  home.packages = with pkgs; [
    btop
    iotop
    iftop
    nmap

    usbutils
    pciutils

    which
    tree
    ripgrep
    git-crypt
  ];
}
