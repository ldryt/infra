{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # command line utilities
    which
    tree
    btop
    iotop
    iftop
    ripgrep
    git-crypt
    wl-clipboard

    # gui programs
    libreoffice
    discord
    prismlauncher
    owncloud-client
  ];
}
