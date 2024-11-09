{ config, ... }:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users = {
      colon = import ../../users/colon;
    };
  };

  sops.secrets."users/colon/hashedPassword".neededForUsers = true;
  users = {
    mutableUsers = false;
    users = {
      colon = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        hashedPasswordFile = config.sops.secrets."users/colon/hashedPassword".path;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOJwYm0rvWGewXyk/KwCCSLm4yv5t57zi/+XBz+ugcYE"
        ];
      };
    };
  };
  nix.settings.trusted-users = [ config.users.users.colon.name ];
}
