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
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHlbB0gz194Jq9LSwI2OvsLcA+LgIQMWS2dNNhapaA8K"
        ];
      };
    };
  };
  nix.settings.trusted-users = [ config.users.users.colon.name ];
}
