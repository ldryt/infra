{ config, ... }:
{
  imports = [
    ./hardware
    ./networking.nix
    ./users.nix

    ./services/syncthing.nix
    ./services/nix-cache.nix
    ./services/immich-machine-learning.nix
    ./services/cachefilesd.nix

    ../../modules/nix-settings.nix
    ../../modules/openssh.nix
    ../../modules/fail2ban.nix
    ../../modules/podman.nix
    ../../modules/nginx.nix
    ../../modules/syncthing-relay.nix

    ../../modules/backups.nix
    ../../modules/dns.nix
    ../../modules/monitoring/client.nix
    ../../modules/impermanence.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;
  sops.age.keyFile = "/nix/persist/sops_age_luke.key";

  sops.secrets."backups/restic/hosts/glouton/sshKey" = { };
  sops.secrets."backups/restic/hosts/domus/sshKey" = { };
  sops.secrets."backups/restic/repos/luke/password" = { };
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

  time.timeZone = "Europe/Paris";

  system.stateVersion = "25.11";
}
