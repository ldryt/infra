{ config, ... }:
{
  imports = [
    ../../modules/sd-image-aarch64-tmpfs-root.nix

    ./hardware.nix
    ./networking.nix
    ./users.nix

    ./services/printer

    ../../modules/openssh.nix
    ../../modules/nix-settings.nix
    ../../modules/backups.nix
    ../../modules/fail2ban.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;
  sops.age.keyFile = "/nix/persist/sops_age_printer.key";

  sops.secrets."backups/restic/hosts/glouton/sshKey" = { };
  sops.secrets."backups/restic/hosts/domus/sshKey" = { };
  sops.secrets."backups/restic/repos/printer/password" = { };
  sops.secrets."backups/restic/hosts/gdrive/rclone.conf" = { };
  ldryt-infra.backups = {
    hosts = {
      glouton.sshKey = config.sops.secrets."backups/restic/hosts/glouton/sshKey".path;
      domus.sshKey = config.sops.secrets."backups/restic/hosts/domus/sshKey".path;
      gdrive.rcloneConfigFile = config.sops.secrets."backups/restic/hosts/gdrive/rclone.conf".path;
    };
    repos = {
      #   printer = {
      #     passwordFile = config.sops.secrets."backups/restic/repos/printer/password".path;
      #     paths = [ config.environment.persistence.printer.persistentStoragePath ];
      #   };
    };
  };

  environment.persistence.printer = {
    persistentStoragePath = "/nix/persist";
    directories = [
      "/var/log"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/var/lib/acme"
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_rsa_key"
    ];
  };
  environment.persistence."/nix/tmp".directories = [
    "/tmp"
    "/var/tmp"
  ];

  system.stateVersion = "25.11";
}
