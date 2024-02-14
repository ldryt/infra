{ pkgs, ... }: {
  home.packages = with pkgs; [
    which
    tree
    btop
    iotop
    iftop
    git-crypt

    libreoffice
    spotify
    prismlauncher
  ];
}
