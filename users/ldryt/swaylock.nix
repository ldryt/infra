{ config, lib, pkgs, ... }:
let
  swaylock-cfg = pkgs.writeText "swaylock-cfg" ''
    daemonize
    show-failed-attempts
    ignore-empty-password
    indicator-idle-visible
    indicator-radius=150
    color=000000
    ring-color=ffffff
    inside-ver-color=000000
  '';
  lock = "${pkgs.swaylock}/bin/swaylock --config=${swaylock-cfg}";
in
{
  services.swayidle = {
    enable = true;
    events = [
      {
        event = "lock";
        command = lock;
      }
      {
        event = "before-sleep";
        command = lock;
      }
    ];
  };

  wayland.windowManager.sway.config.keybindings = let
  mod = config.wayland.windowManager.sway.config.modifier;
in lib.mkOptionDefault {
      "${mod}+l" = "exec ${lock}";
    };
}
