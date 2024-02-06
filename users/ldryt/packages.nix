{ pkgs, ... }:
{
  home.packages = with pkgs; [
    which
    tree
    btop
    iotop
    iftop
    libreoffice
    spotify
    prismlauncher

    rustc
    cargo
    rustfmt
    rust-analyzer

    nil
    nixfmt
  ];
}
