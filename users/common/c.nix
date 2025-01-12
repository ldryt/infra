{ pkgs, ... }:
{
  home.packages = with pkgs; [
    autoconf
    autoconf-archive
    automake
    cmake
    valgrind
    gcc
    gdb
    libclang
    gnumake
    criterion
    man-pages
    man-pages-posix
    meson
    ninja
  ];

  home.sessionVariables = {
    ACLOCAL_PATH = "${pkgs.autoconf-archive}/share/aclocal:${pkgs.autoconf}/share/aclocal:${pkgs.automake}/share/aclocal";
  };

  programs.man = {
    enable = true;
    generateCaches = true;
  };
}
