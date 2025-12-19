{ config, ... }:
{
  imports = [
    ./hardware
    ./networking.nix
    ./users.nix

    ./services/syncthing.nix

    ../../modules/nix-settings.nix
    ../../modules/openssh.nix
    ../../modules/fail2ban.nix
    ../../modules/backups.nix
    ../../modules/podman.nix
    ../../modules/dns.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;
  sops.age.keyFile = "/nix/persist/sops_age_luke.key";

  sops.secrets."backups/restic/hosts/glouton/sshKey" = { };
  sops.secrets."backups/restic/hosts/tp420ia/sshKey" = { };
  sops.secrets."backups/restic/repos/luke/password" = { };
  ldryt-infra.backups = {
    hosts = {
      glouton.sshKey = config.sops.secrets."backups/restic/hosts/glouton/sshKey".path;
      tp420ia.sshKey = config.sops.secrets."backups/restic/hosts/tp420ia/sshKey".path;
    };
    repos = {
      luke = {
        passwordFile = config.sops.secrets."backups/restic/repos/luke/password".path;
        paths = [ "/nix/persist" ];
      };
    };
  };

  environment.persistence.luke = {
    persistentStoragePath = "/nix/persist";
    hideMounts = true;
    directories = [
      "/var/log"
      "/var/lib/bluetooth"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/var/lib/sbctl"
      "/var/lib/acme"
      config.services.cachefilesd.cacheDir
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

  services.cachefilesd = {
    enable = true;
    extraConfig = ''
      brun 40%
      bcull 35%
      bstop 30%
    '';
  };

  time.timeZone = "Europe/Paris";

  system.stateVersion = "25.11";
}
