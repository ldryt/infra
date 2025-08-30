{ config, ... }:
{
  imports = [
    ../../modules/sd-image-aarch64.nix

    ./hardware
    ./networking.nix
    ./users.nix

    ./services/printer
    ./services/syncthing.nix

    ../../modules/openssh.nix
    ../../modules/nix-settings.nix
    ../../modules/backups.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;
  sops.age.keyFile = "/nix/sops_age_domus.key";

  services.journald.console = "/dev/tty1";

  boot.loader.timeout = 1;

  sops.secrets."backups/restic/hosts/tp420ia/sshKey" = { };
  sops.secrets."backups/restic/hosts/glouton/sshKey" = { };
  ldryt-infra.backups.hosts = {
    glouton.sshKey = config.sops.secrets."backups/restic/hosts/glouton/sshKey".path;
    tp420ia.sshKey = config.sops.secrets."backups/restic/hosts/tp420ia/sshKey".path;
  };

  system.stateVersion = "24.11";
}
