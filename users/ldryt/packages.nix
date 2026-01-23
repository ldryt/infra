{ pkgs, ... }:
{
  imports = [
    ../common/packages/cli.nix
    ./keypassxc.nix
  ];

  home.packages = with pkgs; [
    nix-tree
    wl-clipboard
    super-slicer-beta
    evolution
    obsidian
    telegram-desktop
    parsec-bin
    libreoffice
    digikam
    prismlauncher
  ];
}
