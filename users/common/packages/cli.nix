{ pkgs, ... }:
{
  home.packages = with pkgs; [
    btop
    iotop
    iftop
    nmap
    tcpdump
    iperf3
    iw
    unzip
    wget
    inotify-tools

    usbutils
    pciutils

    which
    tree
    ripgrep
    sd
    git-crypt
    nix-tree
    restic
    rclone
    encfs

    bluetuith
  ];
}
