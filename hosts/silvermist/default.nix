{ config, modulesPath, ... }:
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
    ./services/mcredir.nix
    ./services/postfix.nix
    ./services/nextcloud.nix
    ./services/ocis.nix

    ../../modules/nginx.nix
    ../../modules/fail2ban.nix
    ../../modules/openssh.nix
    ../../modules/podman.nix
    ../../modules/nix-settings.nix
    ../../modules/backups.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  system.stateVersion = "23.05";
}
