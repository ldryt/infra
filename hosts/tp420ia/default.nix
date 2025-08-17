{ config, ... }:
{
  imports = [
    ./hardware
    ./networking.nix
    ./users.nix

    ./services/sftp-backups.nix
    ./services/ap.nix
    ./services/immich.nix

    ../../modules/nix-settings.nix
    ../../modules/openssh.nix
    ../../modules/fail2ban.nix
    ../../modules/backups.nix
    ../../modules/podman.nix
    ../../modules/dns.nix
    ../../modules/nginx.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;
  sops.age.keyFile = "/nix/persist/sops_age_tp420ia.key";

  sops.secrets."backups/restic/hosts/glouton/sshKey" = { };
  sops.secrets."backups/restic/repos/tp420ia/password" = { };
  ldryt-infra.backups = {
    hosts = {
      glouton.sshKey = config.sops.secrets."backups/restic/hosts/glouton/sshKey".path;
      tp420ia.enable = false;
    };
    repos = {
      tp420ia = {
        passwordFile = config.sops.secrets."backups/restic/repos/tp420ia/password".path;
        paths = [ "/nix/persist" ];
      };
    };
  };

  environment.persistence.tp420ia = {
    persistentStoragePath = "/nix/persist";
    hideMounts = true;
    directories = [
      "/var/log"
      "/var/lib/bluetooth"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/var/cache/powertop"
      "/var/lib/sbctl"
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

  sops.secrets."system/2a37-key" = { };
  environment.etc.crypttab = {
    mode = "0600";
    text = ''
      # <volume-name> <encrypted-device> [key-file] [options]
      2a37-data UUID=2a37da19-450e-4119-adfa-7cb42edb76ba ${config.sops.secrets."system/2a37-key".path}
    '';
  };

  time.timeZone = "Europe/Paris";

  services.openssh.ports = [ 34971 ];

  system.stateVersion = "23.05";
}
