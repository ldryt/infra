{ config, ... }:
{
  imports = [
    ./hardware
    ./networking.nix
    ./users.nix

    ./services/adguardhome.nix
    ./services/syncthing.nix
    ./services/cachefilesd.nix

    ../../modules/nix-settings.nix
    ../../modules/openssh.nix
    ../../modules/fail2ban.nix
    ../../modules/podman.nix
    ../../modules/nginx.nix
    ../../modules/syncthing-relay.nix

    ../../modules/rclone.nix
    ../../modules/backups.nix
    ../../modules/dns.nix
    ../../modules/impermanence.nix
    ../../modules/colon-user.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;
  ldryt-infra.rclone.mounts.scratchpad.umask = "0007";
  sops.age.keyFile = "/nix/persist/sops_age_luke.key";

  sops.secrets."backups/restic/hosts/glouton/sshKey" = { };
  sops.secrets."backups/restic/hosts/domus/sshKey" = { };
  sops.secrets."backups/restic/repos/luke/password" = { };
  ldryt-infra.backups.hosts = {
    glouton.sshKey = config.sops.secrets."backups/restic/hosts/glouton/sshKey".path;
    domus.sshKey = config.sops.secrets."backups/restic/hosts/domus/sshKey".path;
  };

  time.timeZone = "Europe/Paris";

  system.stateVersion = "25.11";
}
