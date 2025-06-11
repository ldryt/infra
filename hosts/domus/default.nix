{ ... }:
{
  imports = [
    ../../modules/sd-image-aarch64.nix

    ./hardware
    ./networking.nix
    ./users.nix

    ./services/home-assistant.nix
    ./services/access-point.nix
    ./services/syncthing.nix
    ./services/printer

    ../../modules/backups.nix
    ../../modules/openssh.nix
    ../../modules/nix-settings.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;
  sops.age.keyFile = "/nix/sops_age_domus.key";

  services.journald.console = "/dev/tty1";

  system.stateVersion = "24.11";
}
