{ pkgs, ... }:
{
  home.packages = with pkgs; [
    which
    tree
    btop
    iotop
    iftop


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
