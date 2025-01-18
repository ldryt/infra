{ pkgs, ... }:
{
  imports = [ ../common/packages/cli.nix ];

  home.packages = with pkgs; [
    nix-tree
    wl-clipboard
    vesktop
    bluetuith
    super-slicer-beta
  ];
}
