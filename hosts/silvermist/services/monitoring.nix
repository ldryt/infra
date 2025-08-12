{ config, ... }:
let
  oidcClientID = "2NADHAc~yxd~kNvfJg4PwJNXE1ErhAcQ2~9FPZEh2TgxLY_GIJdv1LluQGKv38iSy~JYNxo.";
in
{
  environment.persistence.silvermist.directories = [
    {
      directory = config.services.loki.dataDir;
      user = config.services.loki.user;
    }
    {
      directory = config.services.grafana.dataDir;
      user = "grafana";
    }
    {
      directory = "/var/lib/${config.services.prometheus.stateDir}";
      user = "prometheus";
    }
  ];

  services.prometheus = {
    enable = true;
    port = 44141;
    exporters = {
      node = {
        enable = true;
        port = 44191;
        enabledCollectors = [ "systemd" ];
      };
    };
    scrapeConfigs = [
      {
        job_name = "nodes";
        static_configs = [
          {
            targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ];
          }
        ];
      }
    ];
  };

  services.loki = {
    enable = true;
    configuration = {
      server = {
        http_listen_port = 44142;
        grpc_listen_port = 44192;
      };
      auth_enabled = false;
      common = {
        instance_addr = "127.0.0.1";
        path_prefix = config.services.loki.dataDir;
        storage.filesystem = {
          chunks_directory = config.services.loki.dataDir + "/chunks";
          rules_directory = config.services.loki.dataDir + "/rules";
        };
        ring.kvstore.store = "inmemory";
        replication_factor = 1;
      };
      schema_config.configs = [
        {
          from = "1970-01-01";
          index = {
            period = "24h";
            prefix = "index_";
          };
          object_store = "filesystem";
          schema = "v13";
          store = "tsdb";
        }
      ];
    };
  };

  services.promtail = {
    enable = true;
    configuration = {
      server.http_listen_port = 44143;
      clients = [
        {
          url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}/loki/api/v1/push";
        }
      ];
      scrape_configs = [
        {
          job_name = "journal";
          journal = {
            max_age = "12h";
            labels.job = "systemd-journal";
          };
          relabel_configs = [
            {
              source_labels = [ "__journal__systemd_unit" ];
              target_label = "unit";
            }
          ];
        }
      ];
    };
  };

  sops.secrets."services/grafana/adminPassword".owner = "grafana";
  sops.secrets."services/grafana/mail/clearPassword".owner = "grafana";
  sops.secrets."services/grafana/oidc/clientSecret".owner = "grafana";
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = 44144;
        domain = "${config.ldryt-infra.dns.records.grafana}";
        root_url = "https://${config.services.grafana.settings.server.domain}/";
      };
      analytics.feedback_links_enabled = false;
      security.admin_password = "$__file{${config.sops.secrets."services/grafana/adminPassword".path}}";
      "auth.generic_oauth" = {
        enabled = true;
        client_id = oidcClientID;
        client_secret = "$__file{${config.sops.secrets."services/grafana/oidc/clientSecret".path}}";
        auth_url = "https://${config.ldryt-infra.dns.records.authelia}/api/oidc/authorization";
        token_url = "https://${config.ldryt-infra.dns.records.authelia}/api/oidc/token";
        api_url = "https://${config.ldryt-infra.dns.records.authelia}/api/oidc/userinfo";
        scopes = "openid profile email groups";
        empty_scopes = false;
        login_attribute_path = "preferred_username";
        groups_attribute_path = "groups";
        name_attribute_path = "name";
        use_pkce = true;
        auto_login = true;
        allow_sign_up = true;
      };
      smtp = {
        enabled = true;
        host = "${config.ldryt-infra.dns.records.mailserver}:465";
        user = "graph@ldryt.dev";
        password = "$__file{${config.sops.secrets."services/grafana/mail/clearPassword".path}}";
        from_address = "graph@ldryt.dev";
        from_name = "Grafana - ldryt.dev";
      };
    };
    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          access = "proxy";
          url = "http://127.0.0.1:${toString config.services.prometheus.port}";
        }
        {
          name = "Loki";
          type = "loki";
          access = "proxy";
          url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}";
        }
      ];
    };
  };

  sops.secrets."services/grafana/mail/hashedPassword" = { };
  mailserver.loginAccounts."graph@ldryt.dev" = {
    hashedPasswordFile = config.sops.secrets."services/grafana/mail/hashedPassword".path;
    sendOnly = true;
  };

  # https://www.authelia.com/integration/openid-connect/grafana/
  services.authelia.instances.main.settings.identity_providers.oidc.clients = [
    {
      client_name = "grafana";
      client_id = oidcClientID;
      client_secret = "$pbkdf2-sha512$310000$JcOWa7BjnZ.spylrhrwBUA$1ztZ/nyYgD1Ke2VQ09WNAh5Cc0ORSYw7vm4Icg7xO5l3AcvpZ1tI9P3uyvGzYhxNVko0fmXtJxalCIvwF5eGcA";
      public = false;
      require_pkce = true;
      pkce_challenge_method = "S256";
      redirect_uris = [
        (config.services.grafana.settings.server.root_url + "login/generic_oauth")
      ];
      scopes = [
        "openid"
        "profile"
        "groups"
        "email"
      ];
      userinfo_signed_response_alg = "none";
      token_endpoint_auth_method = "client_secret_basic";
    }
  ];

  services.nginx.virtualHosts."${config.services.grafana.settings.server.domain}" = {
    enableACME = true;
    forceSSL = true;
    kTLS = true;
    locations."/" = {
      proxyPass = "http://${config.services.grafana.settings.server.http_addr}:${toString config.services.grafana.settings.server.http_port}";
      proxyWebsockets = true;
    };
  };
}
