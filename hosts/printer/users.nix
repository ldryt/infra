{ config, ... }:
{
  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    users = {
      colon = {
        imports = [ ../../users/colon ];
      };
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
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPHMRPMC1gAiL06ibXxQGDfomKbyF/cfNegVKWU2aPvi nixos-anywhere@infra"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMhzJz7w/DgQxQeTsBPrwwnXuk4QIJNXT2hVM8O+LH/S ldryt@tinkerbell"
        ];
      };
    };
  };
  security.sudo.wheelNeedsPassword = false;
  nix.settings.trusted-users = [ config.users.users.colon.name ];
}
