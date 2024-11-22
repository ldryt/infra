{ config, modulesPath, ... }:
{
  imports = [
    ./disk-config.nix
    ./users.nix

    ./services/vaultwarden.nix
    ./services/immich.nix
    ./services/frontpage.nix
    ./services/shlink.nix
    ./services/authelia.nix
    ./services/mcredir.nix
    ./services/postfix.nix
    ./services/nextcloud.nix

    ../../modules/nginx.nix
    ../../modules/fail2ban.nix
    ../../modules/openssh.nix
    ../../modules/podman.nix
    ../../modules/nix-settings.nix
    ../../modules/backups.nix
    ../../modules/net_tuning.nix
  ];

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  sops.defaultSopsFile = ./secrets.yaml;
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  time.timeZone = "Etc/UTC";
  networking = {
    hostName = "silvermist";
    useDHCP = false;
    interfaces."eth0".useDHCP = true;
  };

  system.stateVersion = "23.05";
}
