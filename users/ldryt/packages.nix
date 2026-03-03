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

    kdePackages.dolphin
    kdePackages.ffmpegthumbs
    icoutils
    kdePackages.kdegraphics-thumbnailers
    kdePackages.qtsvg
    kdePackages.kio
    kdePackages.kio-fuse
    kdePackages.kio-extras
    kdePackages.gwenview
    haruna
  ];
}
