{ pkgs, lib, ... }:
{
  imports = [
    ../common/packages/cli.nix
    ./keypassxc.nix
  ];

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "obsidian"
      "parsec-bin"
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
  ];
}
