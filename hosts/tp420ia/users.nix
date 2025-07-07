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
    users.colon = {
      uid = 1042;
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      hashedPasswordFile = config.sops.secrets."users/colon/hashedPassword".path;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILhRiEHBueW2yW+bb+6QoQhNOEFA1tF0F4sTFtEDuPir"
      ];
    };
  };
  security.sudo.wheelNeedsPassword = false;
  nix.settings.trusted-users = [ config.users.users.colon.name ];
}
