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
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOJwYm0rvWGewXyk/KwCCSLm4yv5t57zi/+XBz+ugcYE"
      ];
    };
  };
  nix.settings.trusted-users = [ config.users.users.ldryt.name ];
}
