{ lib, pkgs, ... }:
let
  mod = "Mod4";
  i3lock-color-config = pkgs.writeText "i3lock-color-config" ''
    insidevercolor=00000000
    insidewrongcolor=00000000
    insidecolor=00000000
    ringvercolor=00000000
    ringwrongcolor=00000000
    ringcolor=00000000
    linecolor=00000000
    keyhlcolor=00000000
    bshlcolor=00000000
    separatorcolor=00000000
  '';
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
        "${mod}+l" = "exec ${pkgs.scrot}/bin/scrot - | ${pkgs.imagemagick}/bin/magick convert /dev/stdin RGB:- | ${pkgs.i3lock-color}/bin/i3lock-color --raw $(${pkgs.xorg.xrandr}/bin/xrandr | ${pkgs.gnugrep}/bin/grep '*' | ${pkgs.gawk}/bin/awk {'print $1'}):rgb --image /dev/stdin";
      };
    };
  };
}
