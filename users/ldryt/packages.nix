{ pkgs, ... }:
{
  imports = [
    ../commons/packages/cli.nix
  ];

  home.packages = with pkgs; [
    wl-clipboard
    vesktop
    bluetuith
  ];
}
