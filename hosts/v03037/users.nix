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
    };
  };
  nix.settings.trusted-users = [ config.users.users.colon.name ];
}
