{ ... }:
{
  security.polkit.enable = true;

  services.dbus.enable = true;

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    config = {
      common = {
        default = "wlr";
      };
    };
    wlr.enable = true; # adds pkgs.xdg-desktop-portal-wlr to extraPortals
  };

  # allow swaylock
  security.pam.services.swaylock = {
    text = "auth include login";
  };

  # decrease latency
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

  programs.dconf.enable = true;
}
