{ config, ... }:
{
  services.power-profiles-daemon.enable = true;
  powerManagement.powertop.enable = true;

  services.logind = {
    powerKey = "suspend-then-hibernate";
    powerKeyLongPress = "poweroff";
    lidSwitch = config.services.logind.powerKey;
    lidSwitchDocked = "ignore";
  };

  systemd.sleep.extraConfig = ''
    HibernateDelaySec=3h
  '';

  services.upower = {
    percentageLow = 75;
  };
}
