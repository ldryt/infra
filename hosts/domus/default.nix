{ ... }:
{
  imports = [
    ../../modules/sd-image-aarch64.nix

    ./networking.nix
    ./users.nix

    ./services/home-assistant.nix
    ./services/access-point.nix

    ../../modules/backups.nix
    ../../modules/openssh.nix
    ../../modules/nix-settings.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;
  sops.age.keyFile = "/nix/sops_age_domus.key";

  services.journald.console = "/dev/tty1";

  systemd.services.disable-all-leds = {
    description = "Disable all LEDs on the system";
    wantedBy = [ "multi-user.target" ];
    script = ''
      echo none > /sys/class/leds/ACT/trigger
      echo none > /sys/class/leds/PWR/trigger
    '';
    serviceConfig = {
      Type = "oneshot";
    };
  };

  system.stateVersion = "24.05";
}
