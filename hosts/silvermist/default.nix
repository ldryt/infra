{ config, ... }:
{
  imports = [
    ./hardware.nix
    ./networking.nix
    ./users.nix

    ./services/authelia
    ./services/tunnel.nix
    ./services/mailserver
    ./services/radicale.nix
    ./services/syncthing.nix

    ../../modules/nginx.nix
    ../../modules/fail2ban.nix
    ../../modules/openssh.nix
    ../../modules/podman.nix
    ../../modules/nix-settings.nix
    ../../modules/backups.nix
    ../../modules/dns.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;
  sops.age.keyFile = "/nix/sops_age_silvermist.key";

  sops.secrets."backups/restic/hosts/tp420ia/sshKey" = { };
  sops.secrets."backups/restic/hosts/glouton/sshKey" = { };
  sops.secrets."backups/restic/repos/silvermist/password" = { };
  ldryt-infra.backups = {
    hosts = {
      glouton.sshKey = config.sops.secrets."backups/restic/hosts/glouton/sshKey".path;
      tp420ia.sshKey = config.sops.secrets."backups/restic/hosts/tp420ia/sshKey".path;
    };
    repos = {
      silvermist = {
        passwordFile = config.sops.secrets."backups/restic/repos/silvermist/password".path;
        paths = [ "/nix/persist" ];
      };
    };
  };

  services.cachefilesd = {
    enable = true;
    extraConfig = ''
      brun  20%
      bcull 15%
      bstop 10%
    '';
  };

  environment.persistence.silvermist = {
    persistentStoragePath = "/nix/persist";
    directories = [
      "/var/log"
      "/var/lib/acme"
      "/var/lib/nixos"
      "/var/lib/fail2ban"
      "/var/lib/containers"
      "/var/lib/systemd/coredump"
      "/var/cache"
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

  time.timeZone = "Europe/Paris";

  system.stateVersion = "23.05";
}
