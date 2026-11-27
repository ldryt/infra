{ config, ... }:
{
  imports = [
    ./hardware
    ./networking.nix
    ./users.nix

    ./services/adguardhome.nix
    ./services/archiveteam.nix
    ./services/frontpage.nix
    ./services/shlink.nix
    ./services/umami.nix
    ./services/owntracks.nix
    ./services/coturn.nix
    ./services/authelia
    ./services/mailserver
    ./services/media
    ./services/immich.nix
    ./services/radicale.nix
    ./services/calibre-web.nix
    ./services/wallabag.nix
    ./services/syncthing.nix
    ./services/restic-sftp-host.nix
    ./services/harmonia.nix
    ./services/searxng.nix

    ../../modules/monitoring/server.nix
    ../../modules/nginx.nix
    ../../modules/openssh.nix
    ../../modules/nix-settings.nix
    ../../modules/crowdsec
    ../../modules/syncthing-relay
    ../../modules/snowflake-proxy.nix
    ../../modules/podman.nix
    ../../modules/ripe-atlas.nix
    ../../modules/libvirt.nix
    ../../modules/ntp-pool

    ../../modules/colon-user.nix
    ../../modules/ldryt-remote-user.nix
    ../../modules/impermanence.nix
    ../../modules/rclone.nix
    ../../modules/backups.nix
    ../../modules/dns.nix
  ];

  ldryt-infra.monitoring.blackbox.targets.http_clank_api = [
    "https://pikvm.ldryt.dev/api/info"
    "https://ha.ldryt.dev:48448/api/"
  ];

  nixpkgs.config.allowUnfree = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.age.keyFile = "/nix/persist/sops_age_domus.key";

  ldryt-infra.rclone.mounts = {
    onedrive = { };
    gdrive = { };
    scratchpad.umask = "0007";
  };
  boot.kernel.sysctl."fs.fuse.default_request_timeout" = 120;

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

  sops.secrets."backups/restic/hosts/domus/sshKey" = { };
  sops.secrets."backups/restic/repos/domus/password" = { };
  ldryt-infra.backups.hosts = {
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
      rclone-cache /dev/disk/by-partuuid/3ed96de3-d902-4c78-87b4-bc15ba1a44a1 ${
        config.sops.secrets."system/rclone/cache-key".path
      } luks,nofail,x-systemd.device-timeout=30s
      2a37-data UUID=2a37da19-450e-4119-adfa-7cb42edb76ba ${
        config.sops.secrets."system/2a37-key".path
      } nofail,x-systemd.device-timeout=120s
      archiveteam UUID=1369ab05-584e-4689-812a-a784ce1d83ec ${
        config.sops.secrets."system/media-key".path
      } nofail,x-systemd.device-timeout=30s
    '';
  };

  services.openssh.ports = [
    22
    34971
  ];

  time.timeZone = "Europe/Paris";

  system.stateVersion = "25.11";
}
