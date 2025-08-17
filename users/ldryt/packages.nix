{ pkgs, ... }:
{
  imports = [
    ../common/packages/cli.nix
    ./keypassxc.nix
  ];

  home.packages = with pkgs; [
    nix-tree
    wl-clipboard
    vesktop
    super-slicer-beta
    evolution
    obsidian
    telegram-desktop
    parsec-bin
    libreoffice
    slack
    digikam
  ];
}
