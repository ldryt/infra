{ lib, config, ... }:
{
  services.power-profiles-daemon.enable = true;
  powerManagement.powertop.enable = true;

  services.logind = {
    powerKey = "hibernate";
    powerKeyLongPress = "poweroff";
    lidSwitch = config.services.logind.powerKey;
    lidSwitchDocked = "ignore";
  };
}
