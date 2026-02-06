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
    usbutils
    pciutils

    nmap
    tcpdump
    iperf3
    iw
    wget

    opentofu
    sops

    which
    tree
    ripgrep
    sd
    git-crypt
    nix-tree
    restic
    rclone
    encfs
    ltrace
    file
    unzip
    inotify-tools
    picocom
    minicom
    screen

    uv

    qemu
    e2fsprogs
    cdrkit

    bluetuith
  ];
}
