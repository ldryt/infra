{ pkgs, ... }:
{
  programs.nix-ld.enable = true;
  programs.bcc.enable = true;
  environment.systemPackages = with pkgs; [
    screen
    vault
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
    rpi-imager
    typst
  ];
}
