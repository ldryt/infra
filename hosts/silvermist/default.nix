{ config, ... }:
{
  imports = [
    ./hardware.nix
    ./networking.nix
    ./users.nix

    ./services/vaultwarden.nix
    ./services/immich.nix
    ./services/frontpage.nix
    ./services/shlink.nix
    ./services/authelia.nix
    ./services/ocis.nix
    ./services/domus.nix
    ./services/mailserver.nix
    ./services/radicale.nix

    ../../modules/nginx.nix
    ../../modules/fail2ban.nix
    ../../modules/openssh.nix
    ../../modules/podman.nix
    ../../modules/nix-settings.nix
    ../../modules/backups.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;
  sops.age.keyFile = "/nix/sops_age_silvermist.key";

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
      "/var/cache/fscache"
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

  system.stateVersion = "23.05";
}
