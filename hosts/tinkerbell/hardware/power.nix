{ pkgs, ... }:
{
  services.power-profiles-daemon.enable = true;

  services.logind.settings.Login = {
    HandlePowerKey = "suspend-then-hibernate";
    HandlePowerKeyLongPress = "poweroff";
    PowerKeyIgnoreInhibited = true;
    HandleLidSwitch = "suspend-then-hibernate";
    HandleLidSwitchDocked = "ignore";
    LidSwitchIgnoreInhibited = true;
  };

  # GNOME otherwise takes low-level ownership of these events, preventing
  # logind's suspend-then-hibernate actions from running at all.  Keep root
  # able to inhibit them, but make logind authoritative for desktop sessions.
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      const hardwareEventInhibitors = [
        "org.freedesktop.login1.inhibit-handle-power-key",
        "org.freedesktop.login1.inhibit-handle-lid-switch"
      ];

      if (hardwareEventInhibitors.indexOf(action.id) !== -1 && subject.user !== "root") {
        return polkit.Result.NO;
      }
    });
  '';

  systemd.sleep.settings.Sleep = {
    HibernateDelaySec = "30m";
  };

  services.upower = {
    enable = true;
    percentageLow = 20;
    percentageCritical = 15;
    percentageAction = 10;
    criticalPowerAction = "Hibernate";
  };

  services.udev.extraRules = ''
    SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="0", RUN+="${pkgs.power-profiles-daemon}/bin/powerprofilesctl set power-saver"
    SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="1", RUN+="${pkgs.power-profiles-daemon}/bin/powerprofilesctl set performance"
  '';
}
