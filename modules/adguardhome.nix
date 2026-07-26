{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.ldryt-infra.adguardhome;
  acmeCert = config.security.acme.certs."${config.ldryt-infra.dns.records.adguardhome}";
  mobileconfig = {
    signed = "/run/mobileconfig/dns.mobileconfig";
    raw = pkgs.writeText "dns.mobileconfig" ''
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>PayloadContent</key>
        <array>
          <dict>
            <key>DNSSettings</key>
            <dict>
              <key>DNSProtocol</key>
              <string>HTTPS</string>
              <key>ServerURL</key>
              <string>https://${config.ldryt-infra.dns.records.adguardhome}/dns-query</string>
            </dict>
            <key>PayloadDescription</key>
            <string>Routes all DNS queries over HTTPS to AdGuard Home on ${config.ldryt-infra.dns.records.adguardhome}</string>
            <key>PayloadDisplayName</key>
            <string>Encrypted DNS (DoH)</string>
            <key>PayloadIdentifier</key>
            <string>dev.ldryt.dns.doh</string>
            <key>PayloadOrganization</key>
            <string>ldryt.dev</string>
            <key>PayloadType</key>
            <string>com.apple.dnsSettings.managed</string>
            <key>PayloadUUID</key>
            <string>E28C2075-ADC1-5AA9-9AA9-9F9ECD4E862C</string>
            <key>PayloadVersion</key>
            <integer>1</integer>
          </dict>
        </array>
        <key>PayloadDescription</key>
        <string>Encrypted, ad-blocking DNS provided by ldryt.dev</string>
        <key>PayloadDisplayName</key>
        <string>ldryt.dev Encrypted DNS</string>
        <key>PayloadIdentifier</key>
        <string>dev.ldryt.dns</string>
        <key>PayloadOrganization</key>
        <string>ldryt.dev</string>
        <key>PayloadType</key>
        <string>Configuration</string>
        <key>PayloadUUID</key>
        <string>1291E1ED-C963-4CD4-85B2-44202616B534</string>
        <key>PayloadVersion</key>
        <integer>1</integer>
      </dict>
      </plist>
    '';
  };
in
{
  options.ldryt-infra.adguardhome = {
    enable = lib.mkEnableOption "AdGuard Home";
  };

  config = lib.mkIf cfg.enable ({
    services.adguardhome = {
      enable = true;
      mutableSettings = false;
      host = "127.0.0.1";
      port = 43000;
      settings = {
        dns = {
          bind_hosts = [ "0.0.0.0" ];
          port = 53;
          anonymize_client_ip = true;

          use_http3_upstreams = true;
          upstream_mode = "load_balance";
          upstream_dns = [
            "https://dns10.quad9.net/dns-query"
            "https://cloudflare-dns.com/dns-query"
            "https://dns.mullvad.net/dns-query"
          ];

          bootstrap_dns = [
            "9.9.9.9"
            "149.112.112.112"
          ];
          bootstrap_prefer_ipv6 = false;

          fallback_dns = [
            "9.9.9.9"
            "149.112.112.112"
          ];

          cache_enabled = true;
          cache_size = 4194304;
          cache_optimistic = true;
          enable_dnssec = true;
          ratelimit = 60;
        };

        tls = {
          enabled = true;
          server_name = config.ldryt-infra.dns.records.adguardhome;
          force_https = false;
          port_https = 0;
          port_dns_over_tls = 853;
          port_dns_over_quic = 0;
          allow_unencrypted_doh = true;
          certificate_path = "${acmeCert.directory}/fullchain.pem";
          private_key_path = "${acmeCert.directory}/key.pem";
          strict_sni_check = false;
        };

        filters = [
          {
            enabled = true;
            url = "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/pro.txt";
            name = "Hagezi DNS Blocklist - Multi Pro";
            id = 1;
          }
        ];
        statistics = {
          enabled = true;
          interval = "168h";
        };
        querylog = {
          enabled = true;
          file_enabled = true;
          interval = "24h";
          size_memory = 1000;
        };
        user_rules = [ ];
      };
    };

    networking.firewall.allowedTCPPorts = [ 853 ];

    ldryt-infra.persist.directories = [ "/var/lib/AdGuardHome" ];

    sops.secrets."services/adguardhome/acme/env" = { };

    users.groups.acme-adguardhome = { };
    users.users.nginx.extraGroups = [ "acme-adguardhome" ];
    security.acme.certs."${config.ldryt-infra.dns.records.adguardhome}" = {
      dnsProvider = "desec";
      environmentFile = config.sops.secrets."services/adguardhome/acme/env".path;
      group = "acme-adguardhome";
      reloadServices = [
        "adguardhome.service"
        "mobileconfig-sign.service"
      ];
    };
    systemd.services.adguardhome.serviceConfig.SupplementaryGroups = [ "acme-adguardhome" ];

    services.nginx.virtualHosts."${config.ldryt-infra.dns.records.adguardhome}" = {
      useACMEHost = config.ldryt-infra.dns.records.adguardhome;
      forceSSL = true;
      locations."= /dns-query".proxyPass =
        "http://${config.services.adguardhome.host}:${toString config.services.adguardhome.port}";
      locations."/dns-query/".proxyPass =
        "http://${config.services.adguardhome.host}:${toString config.services.adguardhome.port}";
      locations."/".extraConfig = "return 403;";
      locations."= /dns.mobileconfig" = {
        alias = mobileconfig.signed;
        extraConfig = ''
          default_type application/x-apple-aspen-config;
          add_header Content-Disposition 'attachment; filename="dns.mobileconfig"';
        '';
      };
    };

    systemd.services.mobileconfig-sign = {
      description = "Sign the Apple DNS configuration profile";
      wantedBy = [ "multi-user.target" ];
      wants = [ "acme-finished-${config.ldryt-infra.dns.records.adguardhome}.target" ];
      after = [ "acme-finished-${config.ldryt-infra.dns.records.adguardhome}.target" ];
      before = [ "nginx.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        DynamicUser = true;
        SupplementaryGroups = [ "acme-adguardhome" ];
        RuntimeDirectory = "mobileconfig";
        RuntimeDirectoryMode = "0755";
        RuntimeDirectoryPreserve = "restart";
        UMask = "0022";
        PrivateNetwork = true;
        NoNewPrivileges = true;
        ExecStart = ''
          ${pkgs.openssl}/bin/openssl smime -sign \
            -signer ${acmeCert.directory}/cert.pem \
            -inkey ${acmeCert.directory}/key.pem \
            -certfile ${acmeCert.directory}/chain.pem \
            -in ${mobileconfig.raw} \
            -out ${mobileconfig.signed} \
            -outform der -nodetach -binary
        '';
      };
    };
  });
}
