{ pkgs, ... }:
{
  programs.nix-ld.enable = true;
  programs.bcc.enable = true;
  hardware.saleae-logic.enable = true;
  programs.stm32cubeide.enable = true;
  services.node-red = {
    enable = true;
    openFirewall = true;
    withNpmAndGcc = true;
  };
  services.udev.packages = [ pkgs.usb-blaster-udev-rules ];
  environment.systemPackages = with pkgs; [
    screen
    vault
    heptagon
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
    rpi-imager
    typst
  ];
}
