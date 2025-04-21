{ pkgs, ... }:
{
  home.sessionVariables."QT_QPA_PLATFORM" = "xcb";
  home.packages = [ pkgs.keepassxc ];
}
