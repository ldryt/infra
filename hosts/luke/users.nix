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
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGeykPYiQI3m1Up+GKMeTHZXjMMTwaTKl7+Ab4Ddx0J5 terraform@infra"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG9Psfa7IYe+8Rd4URIIEIYzO6rcRauIQFq+/JGFiqrD ldryt@tinkerbell"
      ];
    };
  };
  security.sudo.wheelNeedsPassword = false;
  nix.settings.trusted-users = [ config.users.users.colon.name ];
}
