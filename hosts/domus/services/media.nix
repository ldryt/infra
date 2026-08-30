{
  config,
  pkgs,
  ...
}:
let
  mediaDir = "/mnt/media";
  stateDir = "/var/lib/nixarr";

  flowfin = pkgs.fetchzip {
    url = "https://github.com/Flowfin/jellyfin-plugin-sso/releases/download/4.3.0-beta.52/community-sso-for-jellyfin_4.3.0.52.zip";
    hash = "sha256-gxPX5uvfvt41Gf0jF860HVKZp60+GcOvfwWKmhI3XAc=";
    stripRoot = false;
  };
  flowfinConfig = pkgs.writeText "flowfin-sso.json" (
    builtins.toJSON {
      FormatVersion = 1;
      Configuration = {
        ManageLoginPageButtons = true;
        OidConfigs.authelia = {
          OidEndpoint = "https://${config.ldryt-infra.dns.records.authelia}";
          OidClientId = "jellyfin";
          OidSecretFile = config.sops.secrets."services/media/jellyfin/oidc_secret".path;
          BaseUrlOverride = "https://${config.ldryt-infra.dns.records.jellyfin}";
          Enabled = true;
          EnableAuthorization = true;
          EnableAllFolders = true;
          Roles = [
            "admin"
            "media"
          ];
          AdminRoles = [ "admin" ];
          RoleClaim = "groups";
          OidScopes = [ "groups" ];
          RequirePkce = true;
          DisablePushedAuthorization = true;
          LoginButtonText = "Sign in with Authelia";
        };
        SamlConfigs = { };
      };
    }
  );
  autheliaDomain = config.ldryt-infra.dns.records.authelia;
  seerrDomain = config.ldryt-infra.dns.records.seerr;
  acmeMail = "security@ldryt.dev";
in
{
  sops.secrets = {
    "services/media/vpn/wg-media.conf".restartUnits = [ "wg.service" ];
    "services/media/jellyfin/oidc_secret" = {
      owner = "jellyfin";
      restartUnits = [ "jellyfin.service" ];
    };
  };

  ldryt-infra.persist.directories = [ stateDir ];

  fileSystems."${mediaDir}" = {
    device = "/dev/mapper/media";
    fsType = "ext4";
    options = [
      "nofail"
      "x-systemd.automount"
      "x-systemd.device-timeout=10s"
      "x-systemd.idle-timeout=5min"
    ];
  };

  systemd.tmpfiles.rules = [ "d ${mediaDir} 2775 root media -" ];
  systemd.services.radarr.unitConfig.RequiresMountsFor = [ mediaDir ];
  systemd.services.sonarr.unitConfig.RequiresMountsFor = [ mediaDir ];
  systemd.services.transmission.unitConfig.RequiresMountsFor = [ mediaDir ];

  nixarr = {
    enable = true;
    inherit mediaDir stateDir;

    vpn = {
      enable = true;
      wgConf = config.sops.secrets."services/media/vpn/wg-media.conf".path;
      exposeOnLAN = false;
      proxyListenAddr = "127.0.0.1";
    };

    transmission = {
      enable = true;
      vpn.enable = true;
      peerPort = 39656;
    };

    jellyfin = {
      enable = true;
      expose.https = {
        enable = true;
        domainName = config.ldryt-infra.dns.records.jellyfin;
        acmeMail = acmeMail;
      };
    };

    seerr = {
      enable = true;
      expose.https = {
        enable = true;
        domainName = config.ldryt-infra.dns.records.seerr;
        acmeMail = acmeMail;
      };
    };

    prowlarr = {
      enable = true;
      settings-sync.enable-nixarr-apps = true;
    };

    sonarr = {
      enable = true;
      settings-sync.transmission = {
        enable = true;
        config.fields.tvCategory = "sonarr";
      };
    };

    radarr = {
      enable = true;
      settings-sync.transmission.enable = true;
    };
  };
  services.flaresolverr.enable = true;

  hardware.graphics.enable = true;
  users.users.jellyfin.extraGroups = [
    "render"
    "video"
  ];
  services.jellyfin = {
    forceEncodingConfig = true;
    hardwareAcceleration = {
      enable = true;
      type = "vaapi";
      device = "/dev/dri/renderD128";
    };
    transcoding = {
      throttleTranscoding = true;
      enableHardwareEncoding = true;
      hardwareDecodingCodecs = {
        h264 = true;
        hevc = true;
        hevc10bit = true;
        mpeg2 = true;
        vp9 = true;
      };
    };
  };

  systemd.services.jellyfin = {
    environment.JELLYFIN_SSO_CONFIG_FILE = flowfinConfig;
    unitConfig.RequiresMountsFor = [ mediaDir ];
    serviceConfig.ExecStartPre = [
      (pkgs.writeShellScript "install-flowfin" ''
        mkdir -p ${stateDir}/jellyfin/data/plugins
        rm -rf -- ${stateDir}/jellyfin/data/plugins/flowfin
        cp -r --no-preserve=mode ${flowfin} ${stateDir}/jellyfin/data/plugins/flowfin
      '')
    ];
  };

  services.nginx.virtualHosts."${seerrDomain}" = {
    locations."/".extraConfig = ''
      auth_request /internal/authelia/authz;

      auth_request_set $user $upstream_http_remote_user;
      auth_request_set $groups $upstream_http_remote_groups;
      auth_request_set $name $upstream_http_remote_name;
      auth_request_set $email $upstream_http_remote_email;

      proxy_set_header Remote-User $user;
      proxy_set_header Remote-Groups $groups;
      proxy_set_header Remote-Name $name;
      proxy_set_header Remote-Email $email;

      auth_request_set $redirection_url $upstream_http_location;
      error_page 401 =302 $redirection_url;
    '';

    locations."/internal/authelia/authz" = {
      recommendedProxySettings = false;
      proxyPass = "https://${autheliaDomain}/api/authz/auth-request";
      extraConfig = ''
        internal;

        proxy_ssl_server_name on;
        proxy_ssl_name ${autheliaDomain};
        proxy_ssl_verify on;
        proxy_ssl_verify_depth 3;
        proxy_ssl_trusted_certificate ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt;

        proxy_set_header Host ${autheliaDomain};
        proxy_set_header X-Original-Method $request_method;
        proxy_set_header X-Original-URL $scheme://$http_host$request_uri;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header Content-Length "";
        proxy_set_header Connection "";

        proxy_pass_request_body off;
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503;
        proxy_redirect http:// $scheme://;
        proxy_http_version 1.1;
        proxy_cache_bypass $cookie_session;
        proxy_no_cache $cookie_session;
        proxy_buffers 4 32k;
        client_body_buffer_size 128k;

        send_timeout 5m;
        proxy_read_timeout 240;
        proxy_send_timeout 240;
        proxy_connect_timeout 240;
      '';
    };
  };

  services.prowlarr.settings.auth.required = "DisabledForLocalAddresses";
  services.sonarr.settings.auth.required = "DisabledForLocalAddresses";
  services.radarr.settings.auth.required = "DisabledForLocalAddresses";
}
