{ config, ... }:
{
  sops.secrets."users/ldryt/hashedPassword".neededForUsers = true;
  users = {
    mutableUsers = false;
    users.ldryt = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "networkmanager"
        "vboxusers"
        "libvirtd"
      ];
      hashedPasswordFile = config.sops.secrets."users/ldryt/hashedPassword".path;
    };
  };
  nix.settings.trusted-users = [ config.users.users.ldryt.name ];

}
