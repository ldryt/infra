{ pkgs, ... }:
{
  imports = [ ../common/packages/cli.nix ];

  home.packages = with pkgs; [
    nix-tree
    wl-clipboard
    vesktop
    super-slicer-beta
    evolution
    keepassxc
  ];
}
