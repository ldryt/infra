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
    clang-tools
    gnumake
    criterion
    man-pages
    man-pages-posix
    meson
    ninja
  ];

  xdg.configFile."clangd/config.yaml".text = ''
    CompileFlags:
      Add: [-std=c++20]
  '';

  home.sessionVariables = {
    ACLOCAL_PATH = "${pkgs.autoconf-archive}/share/aclocal:${pkgs.autoconf}/share/aclocal:${pkgs.automake}/share/aclocal";
  };

  programs.man = {
    enable = true;
    generateCaches = true;
  };
}
