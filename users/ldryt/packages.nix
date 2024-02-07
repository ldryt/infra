{ pkgs, ... }:
{
  home.packages = with pkgs; [
    which
    tree
    btop
    iotop
    iftop
    
    git-crypt


    rustc
    cargo
    rustfmt
    rust-analyzer

    nil
    nixfmt

    
    libreoffice
    spotify
    prismlauncher
  ];
}
