{ config, modulesPath, ... }:
{
  imports = [
    ./disk-config.nix

    ./services/ocis.nix
    ./services/vaultwarden.nix
    ./services/immich.nix
    ./services/keycloak.nix
    ./services/frontpage.nix
    ./services/shlink.nix

    ../../modules/nginx.nix
    ../../modules/fail2ban.nix
    ../../modules/openssh.nix
    ../../modules/podman.nix
    ../../modules/nix-settings.nix
    ../../modules/backups.nix
    ../../modules/net_tuning.nix

    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
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

  sops.secrets."users/colon/hashedPassword".neededForUsers = true;
  users = {
    mutableUsers = false;
    users.colon = {
      uid = 1000;
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      hashedPasswordFile = config.sops.secrets."users/colon/hashedPassword".path;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII15TWK7X30dmgSO3izk1NFiMB6LAAWztoEAx2qKC/X7"
      ];
    };
  };
  security.sudo.wheelNeedsPassword = false;
  nix.settings.trusted-users = [ config.users.users.colon.name ];

  system.stateVersion = "23.05";
}
