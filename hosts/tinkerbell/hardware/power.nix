{ pkgs, ... }:
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

  systemd.services.low-battery-hibernate = {
    description = "Hibernate on low battery";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "low-battery-check" ''
        capacity=$(cat /sys/class/power_supply/BAT1/capacity)
        status=$(cat /sys/class/power_supply/BAT1/status)
        if [ "$status" = "Discharging" ] && [ "$capacity" -le 5 ]; then
          systemctl hibernate
        fi
      '';
    };
  };

  systemd.timers.low-battery-hibernate = {
    description = "Check battery level every minute";
    wantedBy = [ "timers.target" ];
    timerConfig.OnActiveSec = "1min";
  };
}
