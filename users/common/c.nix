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
    clang_12
    llvmPackages_12.llvm
    llvmPackages_12.lld
  ];

  home.sessionVariables = {
    ACLOCAL_PATH = "${pkgs.autoconf-archive}/share/aclocal:${pkgs.autoconf}/share/aclocal:${pkgs.automake}/share/aclocal";
  };

  programs.man = {
    enable = true;
    generateCaches = true;
  };
}
