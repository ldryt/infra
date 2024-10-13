{ lib, pkgs, ... }:
let
  mod = "Mod4";
in
{
  xsession.windowManager.i3 = {
    enable = true;
    config = {
      modifier = mod;
      startup = [
        { command = "firefox"; }
        { command = "alacritty"; }
      ];
      keybindings = lib.mkOptionDefault {
        "${mod}+l" = "exec ${pkgs.imagemagick}/bin/magick convert ${./wallpaper.jpg} RGB:- | i3lock --raw $(${pkgs.xorg.xrandr}/bin/xrandr | ${pkgs.gnugrep}/bin/grep '*' | ${pkgs.gawk}/bin/awk {'print $1'}):rgb --image /dev/stdin";
      };
    };
    extraConfig = ''
      exec_always feh --bg-scale --zoom fill ${./wallpaper.jpg}
      exec_always ${pkgs.picom}/bin/picom
    '';
  };
}
