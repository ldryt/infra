{ config, ... }:
{
  imports = [
    ./hardware.nix
    ./networking.nix
    ./users.nix

    ./services/adguardhome.nix
    # ./services/farmlab-tunnel.nix
    ./services/syncthing.nix
    ./services/cachefilesd.nix

    ../../modules/nginx.nix
    ../../modules/fail2ban.nix
    ../../modules/openssh.nix
    ../../modules/podman.nix
    ../../modules/nix-settings.nix
    ../../modules/syncthing-relay.nix

    ../../modules/rclone.nix
    ../../modules/backups.nix
    ../../modules/dns.nix
    ../../modules/monitoring/client.nix
    ../../modules/impermanence.nix
    ../../modules/colon-user.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;
  ldryt-infra.rclone.mounts.scratchpad.umask = "0007";
  sops.age.keyFile = "/nix/sops_age_silvermist.key";

  sops.secrets."backups/restic/hosts/domus/sshKey" = { };
  sops.secrets."backups/restic/hosts/glouton/sshKey" = { };
  sops.secrets."backups/restic/repos/silvermist/password" = { };
  ldryt-infra.backups.hosts = {
    glouton.sshKey = config.sops.secrets."backups/restic/hosts/glouton/sshKey".path;
    domus.sshKey = config.sops.secrets."backups/restic/hosts/domus/sshKey".path;
  };

  sops.secrets."services/monitoring/wg/privateKey" = { };
  ldryt-infra.monitoring.client = {
    enable = true;
    wg.privateKeyFile = config.sops.secrets."services/monitoring/wg/privateKey".path;
  };

  time.timeZone = "Europe/Paris";

  system.stateVersion = "23.05";
}
