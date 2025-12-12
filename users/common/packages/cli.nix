{ pkgs, ... }:
{
  home.packages = with pkgs; [
    atop
    btop
    iotop
    iftop
    nvtopPackages.amd
    perf
    wavemon

    screen
    nmap
    tcpdump
    iperf3
    iw
    unzip
    wget
    inotify-tools

    usbutils
    pciutils

    uv

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
