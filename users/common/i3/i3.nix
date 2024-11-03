{ lib, pkgs, ... }:
let
  mod = "Mod4";
  colorscheme = import ./colorscheme.nix;
in
{
  imports = [
    ./i3status.nix
  ];

  xsession.windowManager.i3 = {
    enable = true;
    config = {
      modifier = mod;
      keybindings = lib.mkOptionDefault {
        "${mod}+l" = "exec i3lock";
      };
    };
    bars = [
      {
        statusCommand = "${pkgs.i3status}/bin/i3status";
        colors = colorscheme.bar;
      }
    ];
    colors = colorscheme.client;
    extraConfig = ''
      exec_always feh --bg-scale --zoom fill ${./wallpaper.jpg}
    '';
  };
}
