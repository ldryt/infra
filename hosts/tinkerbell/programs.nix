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
}
