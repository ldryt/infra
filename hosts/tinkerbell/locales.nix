{ lib, ... }:
{
  time.timeZone = lib.mkDefault "Europe/Paris";
  services.automatic-timezoned.enable = true;
  systemd.services.automatic-timezoned = {
    wants = [
      "network-online.target"
      "time-sync.target"
    ];
    after = [
      "network-online.target"
      "time-sync.target"
    ];
    serviceConfig.Restart = "on-failure";
  };

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_TIME = "en_US.UTF-8";
    LC_NAME = "fr_FR.UTF-8";
    LC_PAPER = "fr_FR.UTF-8";
    LC_ADDRESS = "fr_FR.UTF-8";
    LC_NUMERIC = "fr_FR.UTF-8";
    LC_MONETARY = "fr_FR.UTF-8";
    LC_TELEPHONE = "fr_FR.UTF-8";
    LC_MEASUREMENT = "fr_FR.UTF-8";
    LC_IDENTIFICATION = "fr_FR.UTF-8";
  };
}
