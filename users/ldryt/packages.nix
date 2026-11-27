{ pkgs, ... }:
{
  imports = [ ./keypassxc.nix ];

  home.packages = with pkgs; [
    nix-tree
    wl-clipboard
    super-slicer-beta
    evolution
    obsidian
    signal-desktop
    parsec-bin
    libreoffice
    digikam
    prismlauncher
  ];
}
