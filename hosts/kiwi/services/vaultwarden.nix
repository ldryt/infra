{ config, pkgs, ... }:
let
  hidden = import ../../../secrets/obfuscated.nix;
  vaultwardenSubdomain = "pass";
  gloutonPath = "/mnt/glouton";
  backupDirName = "backups-pool";
  backupGroupName = "backupShare";
in {
  services.vaultwarden = {
    enable = true;
    config = {
      DOMAIN = "https://${vaultwardenSubdomain}.${hidden.ldryt.host}";
      SIGNUPS_ALLOWED = "false";
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 44083;
    };
    backupDir = "${gloutonPath}/${backupDirName}/vaultwarden";
  };

  services.nginx = {
    virtualHosts."${vaultwardenSubdomain}.${hidden.ldryt.host}" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        recommendedProxySettings = true;
        proxyPass =
          "http://${config.services.vaultwarden.config.ROCKET_ADDRESS}:${
            toString config.services.vaultwarden.config.ROCKET_PORT
          }";
      };
    };
  };

  users.groups.${backupGroupName}.gid = 4441;
  users.users.vaultwarden.extraGroups = [ "${backupGroupName}" ];
  environment.systemPackages = [ pkgs.cifs-utils ];
  fileSystems."${gloutonPath}/${backupDirName}" = {
    device = hidden.kiwi.smb.glouton.${backupDirName}.shareName;
    fsType = "cifs";
    options = [
      "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s,credentials=${
        config.sops.secrets."system/smb/glouton/${backupDirName}/credentials".path
      },gid=${
        toString config.users.groups.${backupGroupName}.gid
      },file_mode=0660,dir_mode=0770,cache=loose,fsc,sfu"
    ];
  };
}
