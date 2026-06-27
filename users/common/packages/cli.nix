{ pkgs, pkgs-master, ... }:
{
  home.packages = with pkgs; [
    atop
    btop
    iotop
    iftop
    nethogs
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
    jq
    git-crypt
    nix-tree
    restic
    rclone
    encfs
    ltrace
    file
    zip
    zlib
    nix-diff
    ncdu
    unzip
    inotify-tools
    picocom
    minicom
    screen
    ncdu

    uv

    qemu
    e2fsprogs
    cdrkit

    bluetuith

    pkgs-master.headlamp
  ];
}
