{
  config,
  lib,
  pkgs,
  ...
}:
let
  common = import ./common.nix { };
  inherit (config.sops) secrets;
  monitoring = config.ldryt-infra.monitoring;
  blackboxTargets = monitoring.blackbox.targets;
in
{
  imports = [
    ./base.nix
    ./json-exporter.nix
  ];

  sops.secrets."services/grafana/adminPassword".owner = "grafana";
  sops.secrets."services/grafana/secretKey".owner = "grafana";
  sops.secrets."services/grafana/oidc/clientSecret".owner = "grafana";
  sops.secrets."services/grafana/mail/clearPassword" = {
    owner = "grafana";
    group = "alertmanager_sops";
    mode = "0440";
  };

  ldryt-infra.monitoring.enable = true;

  ldryt-infra.persist.directories = [
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
    listenAddress = "127.0.0.1";
    port = common.ports.prometheus;
    rules = [ (builtins.readFile ./alerts.yml) ];
    alertmanagers = [
      {
        static_configs = [
          { targets = [ "127.0.0.1:${toString common.ports.alertmanager}" ]; }
        ];
      }
    ];
    exporters.blackbox = lib.mkIf (blackboxTargets != { }) {
      enable = true;
      listenAddress = "127.0.0.1";
      port = common.ports.blackbox;
      configFile = pkgs.writeText "blackbox.yml" ''
        modules:
          http_ok:
            prober: http
            timeout: 5s
            http:
              valid_http_versions: ["HTTP/1.1", "HTTP/2.0"]
              follow_redirects: true
          http_protected:
            prober: http
            timeout: 5s
            http:
              valid_status_codes: [401, 403, 302]
              follow_redirects: false
          http_clank_api:
            prober: http
            timeout: 5s
            http:
              valid_status_codes: [401]
              follow_redirects: false
              fail_if_body_not_matches_regexp: ['UnauthorizedError|^401: Unauthorized']
          tcp_connect:
            prober: tcp
            timeout: 5s
          tcp_fail:
            prober: tcp
            timeout: 5s
      '';
    };

    scrapeConfigs =
      lib.mapAttrsToList (
        job_name: endpoint:
        {
          inherit job_name;
          metrics_path = endpoint.metricsPath;
          params = lib.mapAttrs (_: value: [ value ]) endpoint.params;
          static_configs = [
            {
              targets = [ "${monitoring.listenAddress}:${toString endpoint.port}" ];
              labels.instance = config.networking.hostName;
            }
          ] ++ lib.optional (job_name == "nodes") {
            targets = [ "192.168.1.3:${toString common.ports.nodeExporter}" ];
            labels = {
              instance = "clank";
              alert_host_down = "true";
            };
          };
        }
        // lib.optionalAttrs (endpoint.scrapeInterval != null) { scrape_interval = endpoint.scrapeInterval; }
      ) monitoring.endpoints
      ++ lib.mapAttrsToList (module: targets: {
        job_name = "blackbox_${module}";
        metrics_path = "/probe";
        static_configs = map (target: {
          targets = [ "127.0.0.1:${toString common.ports.blackbox}" ];
          labels = {
            instance = target;
            __param_target = target;
            __param_module = module;
          };
        }) targets;
      }) blackboxTargets;
  };

  users.groups.alertmanager_sops = { };
  systemd.tmpfiles.rules = [ "d /var/lib/private 0700 root root -" ];
  systemd.services.alertmanager.serviceConfig.SupplementaryGroups = [ "alertmanager_sops" ];
  services.prometheus.alertmanager = {
    enable = true;
    port = common.ports.alertmanager;
    listenAddress = "127.0.0.1";
    configuration = {
      route = {
        receiver = "email";
        group_by = [
          "alertname"
          "instance"
          "name"
        ];
      };
      receivers = [
        {
          name = "email";
          email_configs = [
            {
              send_resolved = true;
              to = "postmaster+alerts@ldryt.dev";
              smarthost = "${config.ldryt-infra.dns.records.mailserver}:465";
              require_tls = false;
              from = "graph@ldryt.dev";
              auth_username = "graph@ldryt.dev";
              auth_password_file = secrets."services/grafana/mail/clearPassword".path;
              headers.Subject = "[{{ .Status | toUpper }}] {{ .CommonLabels.alertname }} on {{ .CommonLabels.instance }}";
              html = "";
              text = ''
                {{ range .Alerts }}{{ .Annotations.summary }}
                {{ if and (eq .Labels.alertname "SystemdUnitFailed") (eq .Labels.instance "${config.networking.hostName}") }}https://${config.ldryt-infra.dns.records.grafana}/d/sadlil-loki-apps-dashboard?var-host={{ .Labels.instance | urlquery }}&var-unit={{ .Labels.name | urlquery }}&time={{ .StartsAt.UnixMilli }}&time.window=3600000{{ end }}
                {{ end }}
              '';
            }
          ];
        }
      ];
    };
  };

  services.loki = {
    enable = true;
    configuration = {
      server = {
        http_listen_address = "127.0.0.1";
        grpc_listen_address = "127.0.0.1";
        http_listen_port = common.ports.loki;
        grpc_listen_port = common.ports.lokiGrpc;
        log_level = "warn";
      };
      auth_enabled = false;
      limits_config.retention_period = "2160h";
      compactor = {
        working_directory = config.services.loki.dataDir + "/compactor";
        retention_enabled = true;
        delete_request_store = "filesystem";
      };
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

  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = common.ports.grafana;
        domain = config.ldryt-infra.dns.records.grafana;
        root_url = "https://${config.services.grafana.settings.server.domain}/";
      };
      analytics.feedback_links_enabled = false;
      security = {
        admin_password = "$__file{${secrets."services/grafana/adminPassword".path}}";
        secret_key = "$__file{${secrets."services/grafana/secretKey".path}}";
      };
      "auth.generic_oauth" = {
        enabled = true;
        name = "${config.ldryt-infra.dns.records.authelia}";
        client_id = common.grafanaClientId;
        client_secret = "$__file{${secrets."services/grafana/oidc/clientSecret".path}}";
        auth_url = "https://${config.ldryt-infra.dns.records.authelia}/api/oidc/authorization";
        token_url = "https://${config.ldryt-infra.dns.records.authelia}/api/oidc/token";
        api_url = "https://${config.ldryt-infra.dns.records.authelia}/api/oidc/userinfo";
        scopes = "openid profile email groups";
        use_pkce = true;
        auto_login = true;
        allow_sign_up = true;

        # Grafana evaluates twice (Authelia ID Token and Userinfo API)
        # Falls back to an empty string so Grafana ignores the ID Token pass
        role_attribute_path = "contains(groups || `[]`, 'admin') && 'GrafanaAdmin' || contains(groups || `[]`, 'grafana') && 'Admin' || ''";
        allow_assign_grafana_admin = true;
      };
      smtp = {
        enabled = true;
        host = "${config.ldryt-infra.dns.records.mailserver}:465";
        user = "graph@ldryt.dev";
        password = "$__file{${secrets."services/grafana/mail/clearPassword".path}}";
        from_address = "graph@ldryt.dev";
        from_name = "Grafana - ldryt.dev";
      };
    };
    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          uid = "PBFA97CFB590B2093";
          type = "prometheus";
          access = "proxy";
          url = "http://127.0.0.1:${toString common.ports.prometheus}";
        }
        {
          name = "Loki";
          uid = "P8E80F9AEF21F6940";
          type = "loki";
          access = "proxy";
          url = "http://127.0.0.1:${toString common.ports.loki}";
        }
        {
          name = "Alertmanager";
          type = "alertmanager";
          access = "proxy";
          url = "http://127.0.0.1:${toString common.ports.alertmanager}";
          jsonData.implementation = "prometheus";
        }
      ];
      dashboards.settings.providers = [
        {
          name = "default";
          type = "file";
          disableDeletion = false;
          updateIntervalSeconds = 3600;
          options.path = ./dashboards;
        }
      ];
    };
  };

  services.nginx.virtualHosts."${config.services.grafana.settings.server.domain}" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString common.ports.grafana}";
      proxyWebsockets = true;
    };
  };
}
