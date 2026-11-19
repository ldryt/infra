{
  lib,
  pkgs,
  config,
  ...
}:
let
  monitoring = import ./monitoring/common.nix { };
  journal = type: filters: {
    source = "journalctl";
    journalctl_filter = lib.optional (type != "syslog") "--output=cat" ++ filters;
    labels.type = type;
  };
  syslogFilters =
    lib.optional config.services.openssh.enable "_SYSTEMD_UNIT=sshd.service"
    ++ lib.optional config.services.postfix.enable "_SYSTEMD_UNIT=postfix.service"
    ++ lib.optional config.services.dovecot2.enable "_SYSTEMD_UNIT=dovecot.service";
  autheliaFilters = map (instance: "_SYSTEMD_UNIT=authelia-${instance.name}.service") (
    builtins.filter (instance: instance.enable) (builtins.attrValues config.services.authelia.instances)
  );
  notify = config.ldryt-infra.monitoring.base.enable or false;
  alertOnlyRanges = [
    "82.65.203.15/32"
    "82.67.219.252/32"
    "49.12.97.63/32"
    "10.0.0.0/8"
    "169.254.0.0/16"
    "172.16.0.0/12"
    "192.168.0.0/16"
    "fe80::/10"
  ];
in
{
  networking.firewall.logRefusedConnections = true;
  networking.firewall.interfaces.${monitoring.wg.int}.allowedTCPPorts =
    lib.optional notify monitoring.ports.crowdsec;
  networking.nftables = {
    enable = true;
    flushRuleset = false;
  };

  services.crowdsec = {
    enable = true;
    package = lib.mkIf notify (
      pkgs.crowdsec.overrideAttrs (old: {
        subPackages = old.subPackages ++ [ "cmd/notification-http" ];
      })
    );
    settings = {
      lapi.credentialsFile = "/var/lib/crowdsec/state/local-api-credentials.yaml";
      general.api.server = {
        enable = true;
        online_client = null;
      };
      general.plugin_config = lib.mkIf notify { };
      general.prometheus = lib.mkIf notify {
        listen_addr = config.ldryt-infra.monitoring.base.listenAddress;
        listen_port = monitoring.ports.crowdsec;
      };
    };
    hub.parsers = [
      "crowdsecurity/syslog-logs"
      "crowdsecurity/dateparse-enrich"
    ];
    hub.scenarios = lib.optional config.services.openssh.enable "LePresidente/ssh-bad-keyexchange-bf";
    hub.collections = [
      "crowdsecurity/iptables"
    ]
    ++ lib.optionals config.services.nginx.enable [
      "crowdsecurity/nginx"
      "crowdsecurity/http-dos"
    ]
    ++ lib.optional config.services.openssh.enable "crowdsecurity/sshd"
    ++ lib.optional config.services.postfix.enable "crowdsecurity/postfix"
    ++ lib.optional config.services.dovecot2.enable "crowdsecurity/dovecot"
    ++ lib.optional (autheliaFilters != [ ]) "LePresidente/authelia"
    ++ lib.optional config.services.grafana.enable "LePresidente/grafana"
    ++ lib.optional config.services.jellyfin.enable "LePresidente/jellyfin"
    ++ lib.optional config.services.immich.enable "gauth-fr/immich"
    ++ lib.optional config.services.adguardhome.enable "LePresidente/adguardhome";

    localConfig.parsers.s02Enrich = [
      {
        name = "ldryt-infra/trusted-addresses";
        whitelist = {
          reason = "Trusted infrastructure";
          cidr = [
            "127.0.0.0/8"
            "::1/128"
          ]
          ++ [ "10.44.128.0/24" ]
          ++ lib.optionals (!notify) alertOnlyRanges;
        };
      }
    ];

    localConfig.profiles = lib.mkIf notify (
      lib.mkOptionDefault (
        lib.mkBefore [
          {
            name = "local_address_alert";
            filters = [
              ''
                Alert.Remediation == true && Alert.GetScope() == 'Ip' &&
                  any(${builtins.toJSON alertOnlyRanges}, IpInRange(Alert.GetValue(), #))
              ''
            ];
            notifications = [ "alertmanager" ];
            on_success = "break";
          }
        ]
      )
    );

    localConfig.notifications = lib.optional notify {
      name = "alertmanager";
      type = "http";
      method = "POST";
      url = "http://${monitoring.wg.server.ip}:${toString monitoring.ports.alertmanager}/api/v2/alerts";
      headers."Content-Type" = "application/json";
      format = ''
        [{{ range $i, $alert := . }}{{ if $i }},{{ end }}
          {
            "labels": {
              "alertname": "CrowdSecLocalDetection",
              "instance": ${builtins.toJSON config.networking.hostName},
              "source_ip": {{ toJson $alert.Source.IP }},
              "scenario": {{ toJson $alert.Scenario }}
            },
            "annotations": {
              "summary": {{ toJson $alert.Message }}
            }
          }
        {{ end }}]
      '';
    };

    localConfig.acquisitions = [
      (journal "syslog" [
        "_TRANSPORT=kernel"
        "--grep=^refused connection:"
      ])
    ]
    ++ lib.optionals config.services.nginx.enable [
      {
        source = "file";
        filenames = [ "/var/log/nginx/access.log" ];
        labels.type = "nginx";
      }
      (journal "nginx" [ "_SYSTEMD_UNIT=nginx.service" ])
    ]
    ++ lib.optional (syslogFilters != [ ]) (journal "syslog" syslogFilters)
    ++ lib.optional (autheliaFilters != [ ]) (journal "authelia" autheliaFilters)
    ++ lib.optional config.services.grafana.enable (
      journal "grafana" [ "_SYSTEMD_UNIT=grafana.service" ]
    )
    ++ lib.optional config.services.jellyfin.enable (
      journal "jellyfin" [ "_SYSTEMD_UNIT=jellyfin.service" ]
    )
    ++ lib.optional config.services.immich.enable (
      journal "immich" [ "_SYSTEMD_UNIT=immich-server.service" ]
    )
    ++ lib.optional config.services.adguardhome.enable (
      journal "adguardhome" [ "_SYSTEMD_UNIT=adguardhome.service" ]
    );
  };

  services.crowdsec-firewall-bouncer = {
    enable = true;
    settings.nftables = {
      ipv4.set-only = false;
      ipv6.set-only = false;
    };
  };
  # Bouncer registration invokes cscli without --config
  environment.etc."crowdsec/config.yaml".source =
    (pkgs.formats.yaml { }).generate "crowdsec.yaml"
      config.services.crowdsec.settings.general;
  # CrowdSec requires the plugin executable to be owned by its service user
  environment.etc."crowdsec/plugins/notification-http" = lib.mkIf notify {
    source = "${config.services.crowdsec.package}/bin/notification-http";
    mode = "0500";
    inherit (config.services.crowdsec) user group;
  };

  systemd.services = {
    crowdsec = {
      unitConfig.RequiresMountsFor = "/var/lib/crowdsec/state";
      after = lib.optional (
        notify && config.services.prometheus.alertmanager.enable
      ) "alertmanager.service";
      environment.PATH = lib.makeBinPath [ pkgs.systemd ];
      serviceConfig.SupplementaryGroups = lib.optional config.services.nginx.enable config.services.nginx.group;
    };
    # Let registration manage its key directory without moving the persistent database directory
    crowdsec-firewall-bouncer-register.serviceConfig = {
      StateDirectory = lib.mkForce "crowdsec-firewall-bouncer-register";
      ReadWritePaths = [ "/var/lib/crowdsec/state" ];
    };
    crowdsec-firewall-bouncer.after = [ "crowdsec-firewall-bouncer-register.service" ];
  };
  ldryt-infra.persist.directories = [
    {
      directory = "/var/lib/crowdsec/state";
      mode = "0750";
      inherit (config.services.crowdsec) user group;
    }
    {
      directory = "/var/lib/private/crowdsec-firewall-bouncer-register";
      mode = "0700";
    }
  ];
}
