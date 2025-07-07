{ ... }:
{
  services.power-profiles-daemon.enable = true;
  powerManagement.powertop.enable = true;

  services.logind = {
    powerKey = "ignore";
    powerKeyLongPress = "ignore";
    lidSwitch = "ignore";
    lidSwitchDocked = "ignore";
  };
}
