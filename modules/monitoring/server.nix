{
  config,
  lib,
  pkgs,
  ...
}:
let
  common = import ./common.nix { };
  cfg = config.ldryt-infra.monitoring.server;
in
{
  imports = [ ./base.nix ];

  options.ldryt-infra.monitoring.server = {
    enable = lib.mkEnableOption "monitoring server (Prometheus + Loki + Grafana)";

    wg.privateKeyFile = lib.mkOption {
      type = lib.types.path;
    };

    grafana = {
      adminPasswordFile = lib.mkOption { type = lib.types.path; };
      oidcClientSecretFile = lib.mkOption { type = lib.types.path; };
      mailPasswordFile = lib.mkOption { type = lib.types.path; };
      oidcClientId = lib.mkOption { type = lib.types.str; };
    };

    alertmanager = {
      telegram = {
        botTokenFile = lib.mkOption { type = lib.types.path; };
        chatId = lib.mkOption { type = lib.types.int; };
      };
      mail = {
        passwordFile = lib.mkOption { type = lib.types.path; };
        recipient = lib.mkOption { type = lib.types.str; };
      };
    };

    blackbox.targets = lib.mkOption { type = lib.types.attrsOf (lib.types.listOf lib.types.str); };
  };

  config = lib.mkIf cfg.enable {
    ldryt-infra.monitoring.base = {
      enable = true;
      listenAddress = common.wg.server.ip;
    };

    environment.persistence."${config.networking.hostName}".directories = [
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

    networking.firewall.allowedUDPPorts = [ common.wg.port ];

    networking.wireguard.interfaces."${common.wg.int}" = {
      ips = [ "${common.wg.server.ip}${common.wg.subnet}" ];
      listenPort = common.wg.port;
      privateKeyFile = cfg.wg.privateKeyFile;
      peers = map (client: {
        publicKey = client.pubKey;
        allowedIPs = [ "${client.ip}/32" ];
      }) (builtins.attrValues common.wg.clients);
    };

    networking.firewall.interfaces."${common.wg.int}".allowedTCPPorts = [
      common.ports.loki
      common.ports.lokiGrpc
      common.ports.nodeExporter
    ];

    services.prometheus = {
      enable = true;
      port = common.ports.prometheus;
      rules = [
        ''
          groups:
            - name: nodes
              rules:
                - alert: HostDown
                  expr: up{job="nodes"} == 0
                  for: 2m
                  labels:
                    severity: critical
                  annotations:
                    summary: "Host {{ $labels.instance }} is unreachable"

                - alert: HighCPU
                  expr: (1 - avg by(instance) (rate(node_cpu_seconds_total{mode="idle",job="nodes"}[5m]))) * 100 > 85
                  for: 5m
                  labels:
                    severity: warning
                  annotations:
                    summary: "CPU {{ $value | humanize }}% on {{ $labels.instance }}"

                - alert: HighMemory
                  expr: (1 - node_memory_MemAvailable_bytes{job="nodes"} / node_memory_MemTotal_bytes) * 100 > 90
                  for: 5m
                  labels:
                    severity: warning
                  annotations:
                    summary: "Memory {{ $value | humanize }}% on {{ $labels.instance }}"

                - alert: LowDisk
                  expr: (node_filesystem_avail_bytes{job="nodes"} / node_filesystem_size_bytes) * 100 < 10
                  for: 5m
                  labels:
                    severity: warning
                  annotations:
                    summary: "Low disk on {{ $labels.instance }}{{ $labels.mountpoint }}: {{ $value | humanize }}% free"

                - alert: CriticalDisk
                  expr: (node_filesystem_avail_bytes{job="nodes"} / node_filesystem_size_bytes) * 100 < 5
                  for: 2m
                  labels:
                    severity: critical
                  annotations:
                    summary: "Critical disk on {{ $labels.instance }}{{ $labels.mountpoint }}: {{ $value | humanize }}% free"

                - alert: SystemdServiceFailed
                  expr: node_systemd_unit_state{state="failed"} == 1
                  for: 2m
                  labels:
                    severity: warning
                  annotations:
                    summary: "Service {{ $labels.name }} failed on {{ $labels.instance }}"

            - name: blackbox
              rules:
                - alert: ServiceDown
                  expr: probe_success{job=~"blackbox_.*"} == 0
                  for: 3m
                  labels:
                    severity: critical
                  annotations:
                    summary: "{{ $labels.instance }} probe failed ({{ $labels.job }})"

                - alert: SSLCertExpiringSoon
                  expr: probe_ssl_earliest_cert_expiry{job=~"blackbox_.*"} - time() < 86400 * 7
                  for: 4h
                  labels:
                    severity: critical
                  annotations:
                    summary: "SSL Certificate for {{ $labels.instance }} expires in less than 1 week"
        ''
      ];
      alertmanagers = [
        {
          static_configs = [ { targets = [ "127.0.0.1:${toString common.ports.alertmanager}" ]; } ];
        }
      ];
      exporters = {
        blackbox = {
          enable = true;
          port = common.ports.blackbox;
          configFile = pkgs.writeText "blackbox.yml" ''
            modules:
              http_2xx:
                prober: http
                timeout: 5s
                http:
                  valid_http_versions: ["HTTP/1.1", "HTTP/2.0"]
                  follow_redirects: true
              http_401:
                prober: http
                timeout: 5s
                http:
                  valid_status_codes: [401, 403, 302]
              tcp_connect:
                prober: tcp
                timeout: 5s
              icmp:
                prober: icmp
                timeout: 5s
          '';
        };
      };
      scrapeConfigs = [
        {
          job_name = "nodes";
          static_configs = map (host: {
            targets = [ "${host.ip}:${toString common.ports.nodeExporter}" ];
            labels = {
              instance = host.hostname;
            };
          }) ([ common.wg.server ] ++ (builtins.attrValues common.wg.clients));
        }
      ]
      ++ (lib.mapAttrsToList (module: targets: {
        job_name = "blackbox_${module}";
        metrics_path = "/probe";
        params.module = [ module ];
        static_configs = [ { inherit targets; } ];
        # https://ping --> http://127.0.0.1:44190/probe?target=https://ping&module=http_2xx
        relabel_configs = [
          {
            source_labels = [ "__address__" ];
            target_label = "__param_target";
          }
          {
            source_labels = [ "__param_target" ];
            target_label = "instance";
          }
          {
            target_label = "__address__";
            replacement = "127.0.0.1:${toString common.ports.blackbox}";
          }
        ];
      }) cfg.blackbox.targets);
    };

    users.groups.alertmanager_sops = { };
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
          ];
          routes = [
            {
              matchers = [ "severity=\"critical\"" ];
              receiver = "telegram";
              group_wait = "10s";
            }
            {
              matchers = [ "severity=\"warning\"" ];
              receiver = "email";
              repeat_interval = "24h";
            }
          ];
        };
        receivers = [
          {
            name = "email";
            email_configs = [
              {
                send_resolved = true;
                to = cfg.alertmanager.mail.recipient;
                smarthost = "${config.ldryt-infra.dns.records.mailserver}:465";
                require_tls = false;
                from = "graph@ldryt.dev";
                auth_username = "graph@ldryt.dev";
                auth_password_file = cfg.alertmanager.mail.passwordFile;
              }
            ];
          }
          {
            name = "telegram";
            telegram_configs = [
              {
                bot_token_file = cfg.alertmanager.telegram.botTokenFile;
                chat_id = cfg.alertmanager.telegram.chatId;
                send_resolved = true;
                message = ''
                  {{ if eq .Status "firing" }}FIRING{{ else }}RESOLVED{{ end }}
                  *{{ .GroupLabels.alertname }}* | {{ .GroupLabels.instance }}
                  {{ .CommonAnnotations.summary }}
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
          http_listen_port = common.ports.loki;
          grpc_listen_port = common.ports.lokiGrpc;
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
        security.admin_password = "$__file{${cfg.grafana.adminPasswordFile}}";
        "auth.generic_oauth" = {
          enabled = true;
          client_id = cfg.grafana.oidcClientId;
          client_secret = "$__file{${cfg.grafana.oidcClientSecretFile}}";
          auth_url = "https://${config.ldryt-infra.dns.records.authelia}/api/oidc/authorization";
          token_url = "https://${config.ldryt-infra.dns.records.authelia}/api/oidc/token";
          api_url = "https://${config.ldryt-infra.dns.records.authelia}/api/oidc/userinfo";
          scopes = "openid profile email groups";
          empty_scopes = false;
          login_attribute_path = "preferred_username";
          groups_attribute_path = "groups";
          name_attribute_path = "name";
          role_attribute_path = "contains(groups, 'admin') && 'GrafanaAdmin' || 'Viewer'";
          role_attribute_strict = true;
          allow_assign_grafana_admin = true;
          use_pkce = true;
          auto_login = false;
          allow_sign_up = true;
        };
        smtp = {
          enabled = true;
          host = "${config.ldryt-infra.dns.records.mailserver}:465";
          user = "graph@ldryt.dev";
          password = "$__file{${cfg.grafana.mailPasswordFile}}";
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
            url = "http://127.0.0.1:${toString common.ports.prometheus}";
          }
          {
            name = "Loki";
            type = "loki";
            access = "proxy";
            url = "http://127.0.0.1:${toString common.ports.loki}";
          }
          {
            name = "Alertmanager";
            type = "alertmanager";
            access = "proxy";
            url = "http://127.0.0.1:${toString common.ports.alertmanager}";
          }
        ];
        dashboards.settings.providers = [
          {
            name = "default";
            type = "file";
            disableDeletion = true;
            updateIntervalSeconds = 0;
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
  };
}
