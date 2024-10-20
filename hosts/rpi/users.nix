{ config, ... }:
{
  sops.secrets."users/ldryt/hashedPassword".neededForUsers = true;
  users = {
    mutableUsers = false;
    users.ldryt = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
      ];
      hashedPasswordFile = config.sops.secrets."users/ldryt/hashedPassword".path;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII15TWK7X30dmgSO3izk1NFiMB6LAAWztoEAx2qKC/X7"
      ];
    };
  };
  nix.settings.trusted-users = [ config.users.users.ldryt.name ];
}
