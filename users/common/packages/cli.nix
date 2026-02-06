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

    opentofu
    sops
    vault

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

    heptagon
    uv

    saleae-logic-2
    arduino-ide
    quartus-prime-lite
    surfer
    kicad
    jetbrains.idea
    alire
    opam
    stm32cubemx
    bc
    bison
    coccinelle
    dtc
    dfu-util
    efitools
    flex
    gptfdisk
    graphviz
    imagemagick
    gnutls
    libguestfs
    ncurses
    subunit
    swig
    util-linux
    virtualenv
    gtkwave
    ghdl-llvm

    qemu
    e2fsprogs
    cdrkit
    rpi-imager

    typst

    bluetuith
  ];
}
