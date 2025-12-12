{ ... }:
{
  services.power-profiles-daemon.enable = true;
  powerManagement.powertop.enable = true;

  services.logind.settings.Login = {
    powerKey = "suspend-then-hibernate";
    powerKeyLongPress = "poweroff";
    lidSwitch = "suspend-then-hibernate";
    lidSwitchDocked = "ignore";
  };

  systemd.sleep.extraConfig = ''
    HibernateDelaySec=45m
  '';
}
