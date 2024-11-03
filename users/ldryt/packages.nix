{ pkgs, ... }:
{
  imports = [
    ../common/packages/cli.nix
  ];

  home.packages = with pkgs; [
    wl-clipboard
    vesktop
    bluetuith
  ];
}
