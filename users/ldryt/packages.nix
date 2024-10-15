{ pkgs, ... }:
{
  home.packages = with pkgs; [
    which
    tree
    btop
    iotop
    iftop
    ripgrep
    git-crypt
    wl-clipboard
    vesktop
    bluetuith
  ];
}
