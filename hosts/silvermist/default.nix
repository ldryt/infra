{ config, ... }:
{
  imports = [
    ./hardware.nix
    ./networking.nix
    ./users.nix

    ./services/authelia
    # ./services/farmlab-tunnel.nix
    ./services/coturn.nix
    ./services/mailserver
    ./services/radicale.nix
    ./services/syncthing.nix
    ./services/immich.nix
    ./services/frontpage.nix
    ./services/umami.nix
    ./services/owntracks.nix
    ./services/calibre-web.nix
    ./services/wallabag.nix
    ./services/cachefilesd.nix

    ../../modules/nginx.nix
    ../../modules/fail2ban.nix
    ../../modules/openssh.nix
    ../../modules/podman.nix
    ../../modules/nix-settings.nix
    ../../modules/syncthing-relay.nix

    ../../modules/backups.nix
    ../../modules/dns.nix
    ../../modules/monitoring/server.nix
    ../../modules/impermanence.nix
    ../../modules/colon-user.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;
  sops.age.keyFile = "/nix/sops_age_silvermist.key";

  sops.secrets."backups/restic/hosts/domus/sshKey" = { };
  sops.secrets."backups/restic/hosts/glouton/sshKey" = { };
  sops.secrets."backups/restic/hosts/gdrive/rclone.conf" = { };
  sops.secrets."backups/restic/repos/silvermist/password" = { };
  ldryt-infra.backups = {
    hosts = {
      glouton.sshKey = config.sops.secrets."backups/restic/hosts/glouton/sshKey".path;
      domus.sshKey = config.sops.secrets."backups/restic/hosts/domus/sshKey".path;
      gdrive.rcloneConfigFile = config.sops.secrets."backups/restic/hosts/gdrive/rclone.conf".path;
    };
  };

  sops.secrets."services/monitoring/wg/privateKey" = { };
  sops.secrets."services/grafana/adminPassword".owner = "grafana";
  sops.secrets."services/grafana/oidc/clientSecret".owner = "grafana";
  sops.secrets."services/grafana/mail/clearPassword" = {
    owner = "grafana";
    group = "alertmanager_sops";
    mode = "0440";
  };
  sops.secrets."services/monitoring/alertmanager/botToken" = {
    group = "alertmanager_sops";
    mode = "0440";
  };
  ldryt-infra.monitoring.server = {
    enable = true;
    wg.privateKeyFile = config.sops.secrets."services/monitoring/wg/privateKey".path;
    grafana = {
      adminPasswordFile = config.sops.secrets."services/grafana/adminPassword".path;
      oidcClientSecretFile = config.sops.secrets."services/grafana/oidc/clientSecret".path;
      mailPasswordFile = config.sops.secrets."services/grafana/mail/clearPassword".path;
      oidcClientId = "2NADHAc~yxd~kNvfJg4PwJNXE1ErhAcQ2~9FPZEh2TgxLY_GIJdv1LluQGKv38iSy~JYNxo.";
    };
    alertmanager = {
      telegram = {
        botTokenFile = config.sops.secrets."services/monitoring/alertmanager/botToken".path;
        chatId = 7676142062;
      };
      mail = {
        passwordFile = config.sops.secrets."services/grafana/mail/clearPassword".path;
        recipient = "postmaster+alerts@ldryt.dev";
      };
    };
  };

  time.timeZone = "Europe/Paris";

  system.stateVersion = "23.05";
}
