{ pkgs, config, ... }:
{
  services.power-profiles-daemon.enable = true;
  powerManagement.powertop.enable = true;

  services.logind.settings.Login = {
    HandlePowerKey = "suspend-then-hibernate";
    HandlePowerKeyLongPress = "poweroff";
    HandleLidSwitch = "suspend-then-hibernate";
    HandleLidSwitchDocked = "ignore";
  };

  systemd.sleep.extraConfig = ''
    HibernateDelaySec=30m
  '';

  services.udev.extraRules = ''
    SUBSYSTEM=="power_supply", ATTR{status}=="Discharging", ATTR{capacity}=="[0-5]", RUN+="${config.systemd.package}/bin/systemctl hibernate"
    SUBSYSTEM=="power_supply", ATTR{status}=="Discharging", RUN+="${pkgs.power-profiles-daemon}/bin/powerprofilesctl set power-saver"
    SUBSYSTEM=="power_supply", ATTR{status}=="Charging", RUN+="${pkgs.power-profiles-daemon}/bin/powerprofilesctl set performance"
  '';
}
