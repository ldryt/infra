{
  lib,
  pkgs,
  config,
  ...
}:
let
  monitoring = import ../monitoring/common.nix { };
  notify = config.ldryt-infra.monitoring.enable;
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
  services.crowdsec = {
    package = lib.mkIf notify (
      pkgs.crowdsec.overrideAttrs (old: {
        subPackages = old.subPackages ++ [ "cmd/notification-http" ];
      })
    );
    settings.general.plugin_config = lib.mkIf notify { };
    localConfig.parsers.s02Enrich = [
      {
        name = "ldryt-infra/trusted-addresses";
        whitelist = {
          reason = "Trusted infrastructure";
          cidr = [
            "127.0.0.0/8"
            "::1/128"
            "10.44.128.0/24"
          ]
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
  };

  # CrowdSec requires the plugin executable to be owned by its service user
  environment.etc."crowdsec/plugins/notification-http" = lib.mkIf notify {
    source = "${config.services.crowdsec.package}/bin/notification-http";
    mode = "0500";
    inherit (config.services.crowdsec) user group;
  };

  systemd.services.crowdsec.after = lib.optional (
    notify && config.services.prometheus.alertmanager.enable
  ) "alertmanager.service";
}
