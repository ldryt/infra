{ pkgs, ... }: {
  home.packages = with pkgs; [
    # command line utilities
    which
    tree
    btop
    iotop
    iftop
    ripgrep

    # nix related
    git-crypt
    sops
    colmena
    nixfmt
    nil

    # rust related
    cargo
    rustc
    rustfmt
    rust-analyzer

    # gui programs
    libreoffice
    spotify
    prismlauncher
  ];
}
