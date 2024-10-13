{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    valgrind
    gcc
    gdb
    libclang
    gnumake
  ];
}
