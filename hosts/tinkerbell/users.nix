{ inputs, config, ... }:
{
  home-manager = {
    backupFileExtension = "backup";
    useGlobalPkgs = true;
    useUserPackages = true;
    users = {
      ldryt = import ../../users/ldryt;
    };
    sharedModules = [ inputs.sops-nix.homeManagerModules.sops ];
    extraSpecialArgs = {
      firefox-addons = inputs.firefox-addons;
    };
  };

  sops.secrets."users/ldryt/hashedPassword".neededForUsers = true;
  users = {
    mutableUsers = false;
    users.ldryt = {
      description = "Lucas Ladreyt";
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "networkmanager"
        "disk"
        "vboxusers"
        "docker"
      ];
      hashedPasswordFile = config.sops.secrets."users/ldryt/hashedPassword".path;
    };
  };
  nix.settings.trusted-users = [ config.users.users.ldryt.name ];

}
