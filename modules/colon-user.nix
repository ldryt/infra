{
  config,
  lib,
  pkgs-master,
  ...
}:
let
  cfg = config.ldryt-infra.users.colon;
in
{
  options.ldryt-infra.users.colon = {
    enable = lib.mkEnableOption "colon user";
    uid = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
    };
    authorizedKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      users.colon = import ../users/colon;
      extraSpecialArgs = { inherit pkgs-master; };
    };

    sops.secrets."users/colon/hashedPassword".neededForUsers = true;
    users.mutableUsers = false;
    users.users.colon = {
      uid = lib.mkIf (cfg.uid != null) cfg.uid;
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      hashedPasswordFile = config.sops.secrets."users/colon/hashedPassword".path;
      openssh.authorizedKeys.keys = cfg.authorizedKeys;
    };
    security.sudo.wheelNeedsPassword = false;
    nix.settings.trusted-users = [ "colon" ];
  };
}
