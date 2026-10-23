{ config, ... }:
{
  imports = [
    ./hardware
    ./networking.nix
    ./users.nix

    ./services/adguardhome.nix
    ./services/frontpage.nix
    ./services/shlink.nix
    ./services/umami.nix
    ./services/owntracks.nix
    ./services/coturn.nix
    ./services/authelia
    ./services/mailserver
    ./services/monitoring.nix
    ./services/media.nix
    ./services/immich.nix
    ./services/radicale.nix
    ./services/calibre-web.nix
    ./services/wallabag.nix
    ./services/syncthing.nix
    ./services/restic-sftp-host.nix
    ./services/nix-cache.nix

    ../../modules/nginx.nix
    ../../modules/openssh.nix
    ../../modules/nix-settings.nix
    ../../modules/fail2ban.nix
    ../../modules/syncthing-relay.nix
    ../../modules/podman.nix
    ../../modules/libvirt.nix

    ../../modules/colon-user.nix
    ../../modules/ldryt-remote-user.nix
    ../../modules/impermanence.nix
    ../../modules/rclone.nix
    ../../modules/backups.nix
    ../../modules/dns.nix
  ];

  nixpkgs.config.allowUnfree = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.age.keyFile = "/nix/persist/sops_age_domus.key";

  ldryt-infra.rclone.mounts = {
    onedrive = { };
    gdrive = { };
    glouton = { };
    scratchpad.umask = "0007";
  };

  fileSystems."/var/lib/rclone/cache" = {
    device = "/dev/mapper/rclone-cache";
    fsType = "ext4";
    options = [
      "noatime"
      "nodev"
      "nosuid"
      "nofail"
      "x-systemd.device-timeout=30s"
    ];
  };

  sops.secrets."backups/restic/hosts/glouton/sshKey" = { };
  sops.secrets."backups/restic/hosts/domus/sshKey" = { };
  sops.secrets."backups/restic/repos/domus/password" = { };
  ldryt-infra.backups.hosts = {
    glouton.sshKey = config.sops.secrets."backups/restic/hosts/glouton/sshKey".path;
    domus = {
      enable = true;
      sshKey = config.sops.secrets."backups/restic/hosts/domus/sshKey".path;
    };
  };

  sops.secrets."system/2a37-key" = { };
  sops.secrets."system/media-key" = { };
  sops.secrets."system/rclone/cache-key" = { };
  environment.etc.crypttab = {
    mode = "0600";
    text = ''
      # <volume-name> <encrypted-device> [key-file] [options]
      rclone-cache /dev/disk/by-partuuid/57eb13a5-7816-4624-ae39-43ad41571c7b ${
        config.sops.secrets."system/rclone/cache-key".path
      } luks,nofail,x-systemd.device-timeout=30s
      2a37-data UUID=2a37da19-450e-4119-adfa-7cb42edb76ba ${
        config.sops.secrets."system/2a37-key".path
      } nofail,x-systemd.device-timeout=5s
      media UUID=9a4a7e6c-bad1-4b1e-84d1-60d146b64e2a ${
        config.sops.secrets."system/media-key".path
      } nofail,x-systemd.device-timeout=30s
    '';
  };

  services.openssh.ports = [
    22
    34971
  ];

  system.stateVersion = "25.11";
}
