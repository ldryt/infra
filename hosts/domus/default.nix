{ config, ... }:
{
  imports = [
    ../../modules/sd-image-aarch64-tmpfs-root.nix

    ./hardware
    ./networking.nix
    ./users.nix

    ./services/syncthing.nix
    ./services/restic-sftp-host.nix

    ../../modules/openssh.nix
    ../../modules/nix-settings.nix
    ../../modules/fail2ban.nix

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
  environment.etc.crypttab = {
    mode = "0600";
    text = ''
      # <volume-name> <encrypted-device> [key-file] [options]
      2a37-data UUID=2a37da19-450e-4119-adfa-7cb42edb76ba ${config.sops.secrets."system/2a37-key".path}
    '';
  };

  fileSystems."/mnt/ssd1" = {
    device = "/dev/disk/by-uuid/26639b4e-93f4-44a4-b2ce-1da3bdb25ba8";
    fsType = "exfat";
    options = [
      "defaults"
      "nofail"
    ];
  };

  system.stateVersion = "25.11";
}
