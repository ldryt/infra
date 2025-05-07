{ pkgs, ... }:
{
  services.greetd = {
    enable = true;
    vt = 2;
    settings = {
      default_session.command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd ${pkgs.sway}/bin/sway";
    };
  };
}
