{ config, ... }:
{
  imports = [
    ./hardware
    ./networking.nix
    ./users.nix

    ./services/adguardhome.nix
    ./services/media.nix
    ./services/immich-machine-learning.nix
    ./services/syncthing.nix
    ./services/restic-sftp-host.nix

    ../../modules/nginx.nix
    ../../modules/openssh.nix
    ../../modules/nix-settings.nix
    ../../modules/fail2ban.nix
    ../../modules/syncthing-relay.nix

    ../../modules/colon-user.nix
    ../../modules/impermanence.nix
    ../../modules/backups.nix
    ../../modules/dns.nix
    ../../modules/monitoring/client.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;
  sops.age.keyFile = "/nix/persist/sops_age_domus.key";

  sops.secrets."backups/restic/hosts/glouton/sshKey" = { };
  sops.secrets."backups/restic/repos/domus/password" = { };
  sops.secrets."backups/restic/hosts/gdrive/rclone.conf" = { };
  ldryt-infra.backups = {
    hosts = {
      glouton.sshKey = config.sops.secrets."backups/restic/hosts/glouton/sshKey".path;
      domus.enable = false;
      gdrive.rcloneConfigFile = config.sops.secrets."backups/restic/hosts/gdrive/rclone.conf".path;
    };
  };

  sops.secrets."services/monitoring/wg/privateKey" = { };
  ldryt-infra.monitoring.client = {
    enable = true;
    wg.privateKeyFile = config.sops.secrets."services/monitoring/wg/privateKey".path;
  };

  sops.secrets."system/2a37-key" = { };
  sops.secrets."system/media-key" = { };
  environment.etc.crypttab = {
    mode = "0600";
    text = ''
      # <volume-name> <encrypted-device> [key-file] [options]
      2a37-data UUID=2a37da19-450e-4119-adfa-7cb42edb76ba ${
        config.sops.secrets."system/2a37-key".path
      } nofail,x-systemd.device-timeout=5s
      media UUID=9a4a7e6c-bad1-4b1e-84d1-60d146b64e2a ${
        config.sops.secrets."system/media-key".path
      } nofail,x-systemd.device-timeout=5s
    '';
  };

  services.openssh.ports = [
    22
    34971
  ];

  system.stateVersion = "25.11";
}
