{ config, ... }:
{
  imports = [ ../../../modules/backups.nix ];

  sops.secrets."backups/restic/hosts/domus/sshKey" = { };
  sops.secrets."backups/restic/repos/vidia/password" = { };

  ldryt-infra.backups = {
    hosts.domus.sshKey = config.sops.secrets."backups/restic/hosts/domus/sshKey".path;
    repos.vidia = {
      hosts = [ "domus" ];
      passwordFile = config.sops.secrets."backups/restic/repos/vidia/password".path;
      paths = [ "/nix/persist/home/ldryt" ];
      exclude = [
        "/nix/persist/home/ldryt/.local/share/Steam/steamapps/common"
        "/nix/persist/home/ldryt/.local/share/Steam/steamapps/shadercache"
        "/nix/persist/home/ldryt/.local/share/Steam/steamapps/downloading"
        "/nix/persist/home/ldryt/.local/share/Steam/steamapps/temp"
      ];
      timerConfig = null;
    };
  };

  systemd.services.restore-persist = {
    wantedBy = [ "multi-user.target" ];
    before = [ "greetd.service" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    unitConfig.ConditionPathExists = "!/nix/persist/.restored";
    path = [ "/run/current-system/sw" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      rc=0
      "restic-vidia@domus" snapshots latest || rc=$?
      if [ "$rc" -eq 0 ]; then
        "restic-vidia@domus" restore latest --target /
      elif [ "$rc" -ne 10 ]; then
        exit "$rc"
      fi
      touch /nix/persist/.restored
    '';
  };
}
