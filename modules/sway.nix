{ pkgs, ... }:
{
  security.polkit.enable = true;
  services.dbus.enable = true;
  programs.dconf.enable = true;

  # Note: this should be in the home-manager config,
  # but it only works here...
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
}
