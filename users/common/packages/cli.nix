{ pkgs, ... }:
{
  home.packages = with pkgs; [
    btop
    iotop
    iftop
    nmap
    tcpdump
    iperf3

    usbutils
    pciutils

    which
    tree
    ripgrep
    sd
    git-crypt
    nix-tree
    restic
  ];
}
