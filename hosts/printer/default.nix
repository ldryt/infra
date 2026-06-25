{ config, lib, ... }:
{
  imports = [
    ../../modules/sd-image-aarch64-tmpfs-root.nix

    ./hardware
    ./networking.nix
    ./users.nix

    ./services/printer

    ../../modules/openssh.nix
    ../../modules/nix-settings.nix
    ../../modules/fail2ban.nix
    ../../modules/nginx.nix

    ../../modules/backups.nix
    ../../modules/dns.nix
    ../../modules/monitoring/client.nix
    ../../modules/impermanence.nix
    ../../modules/colon-user.nix
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
  };

  sops.secrets."services/monitoring/wg/privateKey" = { };
  ldryt-infra.monitoring.client = {
    enable = true;
    wg.privateKeyFile = config.sops.secrets."services/monitoring/wg/privateKey".path;
  };

  nix.gc.automatic = lib.mkForce false;
  nix.optimise.automatic = lib.mkForce false;

  system.stateVersion = "25.11";
}
