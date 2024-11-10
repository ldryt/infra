{ pkgs, ... }:
{
  home.packages = with pkgs; [
    valgrind
    gcc
    gdb
    libclang
    gnumake
    criterion
    man-pages
    man-pages-posix
  ];

  programs.man = {
    enable = true;
    generateCaches = true;
  };
}
