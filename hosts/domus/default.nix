{ ... }:
{
  imports = [
    ../../modules/sd-image-aarch64.nix

    ./hardware
    ./networking.nix
    ./users.nix

    ./services/printer

    ../../modules/openssh.nix
    ../../modules/nix-settings.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;
  sops.age.keyFile = "/nix/sops_age_domus.key";

  services.journald.console = "/dev/tty1";

  boot.loader.timeout = 1;

  system.stateVersion = "24.11";
}
