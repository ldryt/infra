{
  config,
  lib,
  pkgs,
  nixosConfigurations,
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
      secretKeyFile = lib.mkOption { type = lib.types.path; };
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
  };

  config = lib.mkIf cfg.enable (
    let
      toRegex = builtins.concatStringsSep "|";
      escapePubKey = lib.replaceStrings [ "+" ] [ "[+]" ];

      allWgPeers = [ common.wg.server ] ++ builtins.attrValues common.wg.clients;
      ephemeralWgPeers = builtins.filter (p: p.isEphemeral or false) allWgPeers;
      permanentWgPeers = builtins.filter (p: !(p.isEphemeral or false)) allWgPeers;

      monitoredHostnames = [ common.wg.server.hostname ] ++ builtins.attrNames common.wg.clients;
      monitoredConfigs = lib.filterAttrs (
        name: _: builtins.elem name monitoredHostnames
      ) nixosConfigurations;

      allMounts = lib.unique (
        lib.flatten (lib.mapAttrsToList (_: c: builtins.attrNames c.config.fileSystems) monitoredConfigs)
      );

      allBlackboxTargets = lib.foldAttrs lib.concat [ ] (
        map (c: c.config.ldryt-infra.monitoring.blackbox.targets) (builtins.attrValues monitoredConfigs)
      );

      allMountsRegex = toRegex allMounts;
      ephemeralClientsRegex = toRegex (
        builtins.attrNames (lib.filterAttrs (_: c: c.isEphemeral or false) common.wg.clients)
      );
      ephemeralWgPubKeysRegex = toRegex (map (p: escapePubKey p.pubKey) ephemeralWgPeers);

      # maps a public_key label to a hostname
      # {{ if eq $labels.public_key "KEY1" }}host1{{ else }}...{{ $labels.public_key }}{{ end }}...
      wgPeerNameTemplate =
        lib.concatMapStrings (
          p: ''{{ if eq $labels.public_key "${p.pubKey}" }}${p.hostname}{{ else }}''
        ) permanentWgPeers
        + "{{ $labels.public_key }}"
        + lib.concatMapStrings (_: "{{ end }}") permanentWgPeers;
    in
    {
      ldryt-infra.monitoring.base = {
        enable = true;
        listenAddress = common.wg.server.ip;
      };

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
                    expr: up{instance!~"${ephemeralClientsRegex}"} == 0
                    for: 1m
                    labels:
                      severity: critical
                    annotations:
                      summary: "Host {{ $labels.instance }} is down"

                  - alert: HighCPUPressure
                    expr: rate(node_pressure_cpu_waiting_seconds_total[5m]) * 100 > 80
                    for: 5m
                    labels:
                      severity: critical
                    annotations:
                      summary: "High CPU Pressure on {{ $labels.instance }}: {{ $value | printf \"%.1f\" }}% stall time"

                  - alert: HighIOPressure
                    expr: rate(node_pressure_io_waiting_seconds_total[5m]) * 100 > 65
                    for: 5m
                    labels:
                      severity: critical
                    annotations:
                      summary: "High I/O wait times on {{ $labels.instance }}: {{ $value | printf \"%.1f\" }}% stall time"

                  - alert: HighMemoryPressure
                    expr: rate(node_pressure_memory_waiting_seconds_total[5m]) * 100 > 65
                    for: 5m
                    labels:
                      severity: critical
                    annotations:
                      summary: "High Memory Pressure on {{ $labels.instance }}: {{ $value | printf \"%.1f\" }}% stall time"

                  - alert: LowDisk
                    expr: (node_filesystem_avail_bytes{mountpoint=~"${allMountsRegex}"} / node_filesystem_size_bytes{mountpoint=~"${allMountsRegex}"}) * 100 < 8
                    for: 5m
                    labels:
                      severity: warning
                    annotations:
                      summary: "Low disk on {{ $labels.instance }}{{ $labels.mountpoint }}: {{ $value | printf \"%.1f\" }}% free"

                  - alert: CriticalDisk
                    expr: (node_filesystem_avail_bytes{mountpoint=~"${allMountsRegex}"} / node_filesystem_size_bytes{mountpoint=~"${allMountsRegex}"}) * 100 < 3
                    for: 2m
                    labels:
                      severity: critical
                    annotations:
                      summary: "Critical disk on {{ $labels.instance }}{{ $labels.mountpoint }}: {{ $value | printf \"%.1f\" }}% free"

                  - alert: SystemdUnitFailed
                    expr: node_systemd_unit_state{state="failed"} == 1
                    for: 2m
                    labels:
                      severity: critical
                    annotations:
                      summary: "Systemd unit {{ $labels.name }} failed on {{ $labels.instance }}"

                  - alert: OOMKillTriggered
                    expr: increase(node_vmstat_oom_kill[5m]) > 0
                    for: 1m
                    labels:
                      severity: critical
                    annotations:
                      summary: "OOM Kill was triggered on {{ $labels.instance }}."

                  - alert: WireguardPeerOffline
                    expr: (time() - wireguard_latest_handshake_seconds{public_key!~"${ephemeralWgPubKeysRegex}"}) > 300
                    for: 2m
                    labels:
                      severity: critical
                    annotations:
                      summary: 'Peer ${wgPeerNameTemplate} has lost connection to {{ $labels.instance }}'

                  - alert: HostReboot
                    expr: time() - node_boot_time_seconds < 60 * 5
                    for: 1m
                    labels:
                      severity: warning
                    annotations:
                      summary: "{{ $labels.instance }} just rebooted"

              - name: blackbox
                rules:
                  - alert: ProbeUnreachable
                    expr: probe_success{job!="blackbox_tcp_fail"} == 0
                    for: 2m
                    labels:
                      severity: critical
                    annotations:
                      summary: "{{ $labels.instance }} probe failed ({{ $labels.job }})"

                  - alert: PortExposed
                    expr: probe_success{job="blackbox_tcp_fail"} == 1
                    for: 2m
                    labels:
                      severity: critical
                    annotations:
                      summary: "Port {{ $labels.instance }} is exposed"

                  - alert: SSLCertExpiring
                    expr: probe_ssl_earliest_cert_expiry - time() < 86400 * 20
                    for: 4h
                    labels:
                      severity: critical
                    annotations:
                      summary: "SSL Certificate for {{ $labels.instance }} expires in less than 20 days"
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
                tcp_connect:
                  prober: tcp
                  timeout: 5s
                tcp_fail:
                  prober: tcp
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
            }) allWgPeers;
          }
        ]
        ++ (lib.mapAttrsToList (module: targets: {
          job_name = "blackbox_${module}";
          metrics_path = "/probe";
          params.module = [ module ];
          static_configs = [ { inherit targets; } ];
          # https://ping --> http://127.0.0.1:44190/probe?target=https://ping&module=http_ok
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
        }) allBlackboxTargets);
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
                repeat_interval = "2h";
              }
              {
                matchers = [ "severity=\"warning\"" ];
                receiver = "email";
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
            log_level = "warn";
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
          security = {
            admin_password = "$__file{${cfg.grafana.adminPasswordFile}}";
            secret_key = "$__file{${cfg.grafana.secretKeyFile}}";
          };
          "auth.generic_oauth" = {
            enabled = true;
            name = "${config.ldryt-infra.dns.records.authelia}";
            client_id = cfg.grafana.oidcClientId;
            client_secret = "$__file{${cfg.grafana.oidcClientSecretFile}}";
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
  );
}
