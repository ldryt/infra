{
  lib,
  pkgs,
  config,
  ...
}:
let
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
in
{
  imports = [ ./notifications.nix ];

  networking.firewall.logRefusedConnections = true;
  networking.nftables = {
    enable = true;
    flushRuleset = false;
  };

  services.crowdsec = {
    enable = true;
    settings = {
      lapi.credentialsFile = "/var/lib/crowdsec/state/local-api-credentials.yaml";
      general.api.server = {
        enable = true;
        online_client = null;
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
  systemd.services = {
    crowdsec = {
      unitConfig.RequiresMountsFor = "/var/lib/crowdsec/state";
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
