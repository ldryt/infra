{ inputs, config, ... }:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users = {
      colon = import ../../users/colon;
    };
    sharedModules = [ inputs.sops-nix.homeManagerModules.sops ];
  };

  sops.secrets."colonHashedPassword".neededForUsers = true;
  users = {
    mutableUsers = false;
    users.colon = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      hashedPasswordFile = config.sops.secrets."colonHashedPassword".path;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMtLuVSXE6lSHCgrr21I3DuC3AO/LyvNTkoboNlxhcrP"
      ];
    };
  };
  security.sudo.wheelNeedsPassword = false;
  nix.settings.trusted-users = [ config.users.users.colon.name ];
}
