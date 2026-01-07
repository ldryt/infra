{ config, pkgs-unstable, ... }:
{
  home-manager = {
    useUserPackages = true;
    users = {
      colon = {
        imports = [ ../../users/colon ];
        nixpkgs = pkgs-unstable;
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
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICg6pfvS/wc+6M2JgGuH5TdYE71S7aOsUn2IjyrR5RbH terraform@infra"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHlbB0gz194Jq9LSwI2OvsLcA+LgIQMWS2dNNhapaA8K ldryt@tinkerbell"
        ];
      };
    };
  };
  security.sudo.wheelNeedsPassword = false;
  nix.settings.trusted-users = [ config.users.users.colon.name ];
}
