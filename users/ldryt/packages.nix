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
    spotify
    discord
    prismlauncher
    owncloud-client
    beeper
  ];
}
