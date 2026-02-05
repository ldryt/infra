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

    screen
    nmap
    tcpdump
    iperf3
    iw
    wget

    uv
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

    qemu
    e2fsprogs
    cdrkit

    bluetuith
  ];
}
