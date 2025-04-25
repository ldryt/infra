{ config, ... }:
{
  services.power-profiles-daemon.enable = true;
  powerManagement.powertop.enable = true;

  services.logind = {
    powerKey = "suspend-then-hibernate";
    powerKeyLongPress = "poweroff";
    lidSwitch = config.services.logind.powerKey;
    lidSwitchDocked = "ignore";
    lidSwitchExternalPower = "ignore";
  };

  services.upower = {
    percentageLow = 75;
  };
}
