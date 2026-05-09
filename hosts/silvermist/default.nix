{ config, ... }:
{
  imports = [
    ./hardware.nix
    ./networking.nix
    ./users.nix

    ./services/authelia
    # ./services/tunnel.nix
    # ./services/coturn.nix
    ./services/mailserver
    ./services/radicale.nix
    ./services/syncthing.nix
    ./services/immich.nix
    ./services/frontpage.nix
    ./services/umami.nix
    ./services/owntracks.nix
    ./services/calibre-web.nix

    ../../modules/nginx.nix
    ../../modules/fail2ban.nix
    ../../modules/openssh.nix
    ../../modules/podman.nix
    ../../modules/nix-settings.nix
    ../../modules/backups.nix
    ../../modules/dns.nix
    ../../modules/syncthing-relay.nix
    ../../modules/monitoring/server.nix
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
    # repos = {
    #   silvermist = {
    #     passwordFile = config.sops.secrets."backups/restic/repos/silvermist/password".path;
    #     paths = [ config.environment.persistence.silvermist.persistentStoragePath ];
    #   };
    # };
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
    blackbox.targets = {
      http_2xx = [
        "https://${config.ldryt-infra.dns.records.grafana}/login"
        "https://${config.ldryt-infra.dns.records.authelia}/api/health"
        "https://${config.ldryt-infra.dns.records.immich}/api/server/ping"
        "https://${config.ldryt-infra.dns.records.owntracks}/"
        "http://luke.${config.ldryt-infra.dns.zone}:22070/status"
        "http://silvermist.${config.ldryt-infra.dns.zone}:22070/status"
        "http://10.114.44.2:3003"
      ];
      http_401 = [
        "https://${config.ldryt-infra.dns.records.immich}/api/auth/status"
        "https://${config.ldryt-infra.dns.records.owntracks}/"
      ];
      tcp_connect = [
        "${config.ldryt-infra.dns.records.mailserver}:465"
        "${config.ldryt-infra.dns.records.mailserver}:993"
        "luke.${config.ldryt-infra.dns.zone}:22067"
        "silvermist.${config.ldryt-infra.dns.zone}:22067"
        "10.44.128.1:44191"
      ];
    };
  };

  services.cachefilesd = {
    enable = true;
    extraConfig = ''
      brun  20%
      bcull 15%
      bstop 10%
    '';
  };

  environment.persistence.silvermist = {
    persistentStoragePath = "/nix/persist";
    directories = [
      "/var/log"
      "/var/lib/acme"
      "/var/lib/nixos"
      "/var/lib/fail2ban"
      "/var/lib/containers"
      "/var/lib/systemd/coredump"
      "/var/cache"
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_rsa_key"
    ];
  };

  environment.persistence."/nix/tmp".directories = [
    "/tmp"
    "/var/tmp"
  ];

  time.timeZone = "Europe/Paris";

  system.stateVersion = "23.05";
}
