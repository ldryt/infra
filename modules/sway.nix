{ config, pkgs, ... }:
{
  security.polkit.enable = true;
  services.dbus.enable = true;
  programs.dconf.enable = true;

  # sway config from hm, for tuigreet
  services.displayManager.sessionPackages = [
    config.home-manager.users.ldryt.wayland.windowManager.sway.package
  ];
  # darkman config in hm
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      darkman
    ];
    config = {
      sway = {
        default = [
          "wlr"
          "gtk"
        ];
        "org.freedesktop.impl.portal.Settings" = [ "darkman" ];
      };
    };
  };

  # fingerprint priority in swaylock
  security.pam.services.swaylock = { };

  # allow real-time priority requests
  security.pam.loginLimits = [
    {
      domain = "@users";
      item = "rtprio";
      type = "-";
      value = 1;
    }
  ];

  security.rtkit.enable = true; # this is required for pipewire real-time access
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  environment.systemPackages = with pkgs; [
    gnupg
    pinentry-curses
  ];
  services.dbus.packages = with pkgs; [ gcr ];
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
}
