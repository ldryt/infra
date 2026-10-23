{ config, ... }:
{
  imports = [ ../../../modules/monitoring/server.nix ];

  sops.secrets."services/monitoring/wg/privateKey" = { };
  sops.secrets."services/grafana/adminPassword".owner = "grafana";
  sops.secrets."services/grafana/secretKey".owner = "grafana";
  sops.secrets."services/grafana/oidc/clientSecret".owner = "grafana";
  sops.secrets."services/grafana/mail/clearPassword" = {
    owner = "grafana";
    group = "alertmanager_sops";
    mode = "0440";
  };
  ldryt-infra.monitoring.server = {
    enable = true;
    wg.privateKeyFile = config.sops.secrets."services/monitoring/wg/privateKey".path;
    grafana = {
      adminPasswordFile = config.sops.secrets."services/grafana/adminPassword".path;
      secretKeyFile = config.sops.secrets."services/grafana/secretKey".path;
      oidcClientSecretFile = config.sops.secrets."services/grafana/oidc/clientSecret".path;
      mailPasswordFile = config.sops.secrets."services/grafana/mail/clearPassword".path;
      oidcClientId = "2NADHAc~yxd~kNvfJg4PwJNXE1ErhAcQ2~9FPZEh2TgxLY_GIJdv1LluQGKv38iSy~JYNxo.";
    };
    alertmanager = {
      shortLinks = {
        nodes = "https://ldryt.dev/link/alerts-nodes";
        logs = "https://ldryt.dev/link/alerts-logs";
        blackbox = "https://ldryt.dev/link/alerts-probes";
      };
      mail = {
        passwordFile = config.sops.secrets."services/grafana/mail/clearPassword".path;
        recipient = "postmaster+alerts@ldryt.dev";
      };
    };
  };
}
