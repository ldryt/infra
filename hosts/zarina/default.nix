{ config, modulesPath, ... }:
{
  imports = [
    ./services/mc.nix

    ../../modules/fail2ban.nix
    ../../modules/openssh.nix
    ../../modules/nix-settings.nix
    ../../modules/backups.nix
    ../../modules/net_tuning.nix

    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  sops.defaultSopsFile = ./secrets.yaml;
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  time.timeZone = "Etc/UTC";
  networking = {
    hostName = "zarina";
    useDHCP = false;
    interfaces."eth0".useDHCP = true;
    firewall.enable = true;
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
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHuxxbBzmH4ucWtoGEfpmnRiM9kVOo1uanhSZdVY6vDZ"
      ];
    };
  };
  security.sudo.wheelNeedsPassword = false;
  nix.settings.trusted-users = [ config.users.users.colon.name ];

  system.stateVersion = "23.05";
}
