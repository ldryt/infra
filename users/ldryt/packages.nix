{ pkgs, ... }: {
  home.packages = with pkgs; [
    # command line utilities
    which
    tree
    btop
    iotop
    iftop
    ripgrep
    git-crypt
    sops
    colmena

    # gui programs
    libreoffice
    spotify
    discord
    prismlauncher
    owncloud-client
  ];
}
