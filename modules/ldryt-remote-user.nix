{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.ldryt-infra.users.ldryt-remote;
in
{
  options.ldryt-infra.users.ldryt-remote = {
    enable = lib.mkEnableOption "ldryt remote shell";
    uid = lib.mkOption {
      type = lib.types.int;
      default = 1444;
    };
    authorizedKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.ldryt = {
      inherit (cfg) uid;
      isNormalUser = true;
      hashedPassword = "!";
      openssh.authorizedKeys.keys = cfg.authorizedKeys;
    };

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      users.ldryt = import ../users/ldryt/remote.nix;
    };

    ldryt-infra.persist.directories = [
      {
        directory = "/home/ldryt";
        user = "ldryt";
        group = "users";
        mode = "0700";
      }
    ];

    programs.mosh.enable = true;
    programs.tmux.enable = true;

    systemd.services.ldryt-tmux = {
      description = "Start ldryt persistent tmux session";
      wantedBy = [ "multi-user.target" ];
      restartIfChanged = false;
      unitConfig.RequiresMountsFor = [ "/home/ldryt" ];
      serviceConfig = {
        Type = "oneshot";
        User = "ldryt";
        Group = "users";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "start-ldryt-tmux" ''
          if ! ${pkgs.tmux}/bin/tmux has-session -t =remote 2>/dev/null; then
            ${pkgs.tmux}/bin/tmux new-session -d -s remote
          fi
        '';
      };
    };
  };
}
