{
  config,
  lib,
  pkgs,
  ...
}:
let
  mediaDir = "/mnt/media";
  stateDir = "/var/lib/nixarr";
  mediaAdminApps = {
    radarr = config.services.radarr.settings.server.port;
    sonarr = config.services.sonarr.settings.server.port;
    prowlarr = config.services.prowlarr.settings.server.port;
    transmission = config.services.transmission.settings.rpc-port;
  };

  seerrOidc = pkgs.seerr.overrideAttrs (
    finalAttrs: _: {
      version = "preview-new-oidc-0bfd615";
      src = pkgs.fetchFromGitHub {
        owner = "seerr-team";
        repo = "seerr";
        rev = "0bfd615c0dcd13b30b15bdf0aa98e23669f55cd2";
        hash = "sha256-YPpicQlArAqWnRbUbtUYlwTJk0AGxcaeQmaYNT0vogo=";
      };
      pnpmDeps = pkgs.fetchPnpmDeps {
        inherit (finalAttrs) pname version src;
        pnpm = pkgs.pnpm_10.override { nodejs-slim = pkgs.nodejs-slim_22; };
        fetcherVersion = 3;
        hash = "sha256-7nBkeXGJfDRSvNesOjOK+Mtzp6SlBvbytyfsQl9eh/Y=";
      };
    }
  );

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
  acmeMail = "security@ldryt.dev";
in
{
  sops.secrets = {
    "services/media/vpn/wg-media.conf".restartUnits = [ "wg.service" ];
    "services/media/jellyfin/oidc_secret" = {
      owner = "jellyfin";
      restartUnits = [ "jellyfin.service" ];
    };
    "services/media/seerr/oidc_secret" = { };
  };
  sops.templates."seerr-oidc.json" = {
    owner = "seerr";
    restartUnits = [ "seerr.service" ];
    content = builtins.toJSON {
      main = {
        applicationUrl = "https://${config.ldryt-infra.dns.records.seerr}";
        oidcLogin = true;
      };
      oidc.providers = [
        {
          slug = "authelia";
          name = "Authelia";
          issuerUrl = "https://${config.ldryt-infra.dns.records.authelia}";
          clientId = "seerr";
          clientSecret = config.sops.placeholder."services/media/seerr/oidc_secret";
          scopes = "openid profile email groups";
          newUserLogin = true;
        }
      ];
    };
  };

  ldryt-infra.persist.directories = [ stateDir ];

  fileSystems."${mediaDir}" = {
    device = "/dev/mapper/media";
    fsType = "ext4";
    options = [
      "defaults"
      "nofail"
      "x-systemd.automount"
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
      package = seerrOidc;
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

  systemd.services.seerr.preStart = ''
    umask 0077

    settings_file=${stateDir}/seerr/settings.json
    if ! test -s "$settings_file"; then
      printf '{}\n' > "$settings_file"
    fi

    ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$settings_file" ${
      config.sops.templates."seerr-oidc.json".path
    } > "$settings_file.new"
    mv "$settings_file.new" "$settings_file"
  '';

  services.nginx.virtualHosts = lib.mapAttrs' (
    name: port:
    lib.nameValuePair config.ldryt-infra.dns.records.${name} {
      enableACME = true;
      forceSSL = true;
      extraConfig = ''
        location /internal/authelia/authz {
          internal;
          proxy_pass https://${config.ldryt-infra.dns.records.authelia}/api/authz/auth-request;

          proxy_set_header X-Original-Method $request_method;
          proxy_set_header X-Original-URL $scheme://$http_host$request_uri;
          proxy_set_header X-Forwarded-For $remote_addr;
          proxy_set_header Content-Length "";
          proxy_set_header Connection "";

          proxy_pass_request_body off;
          proxy_ssl_server_name on;
          proxy_ssl_name ${config.ldryt-infra.dns.records.authelia};
          proxy_ssl_verify on;
          proxy_ssl_trusted_certificate ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt;
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
        }
      '';

      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString port}";
        proxyWebsockets = true;
        extraConfig = ''
          auth_request /internal/authelia/authz;

          auth_request_set $user $upstream_http_remote_user;
          auth_request_set $groups $upstream_http_remote_groups;
          auth_request_set $name $upstream_http_remote_name;
          auth_request_set $email $upstream_http_remote_email;

          proxy_set_header Remote-User $user;
          proxy_set_header Remote-Groups $groups;
          proxy_set_header Remote-Email $email;
          proxy_set_header Remote-Name $name;

          auth_request_set $redirection_url $upstream_http_location;
          error_page 401 =302 $redirection_url;
        '';
      };
    }
  ) mediaAdminApps;

  ldryt-infra.monitoring.blackbox.targets.http_protected = lib.mapAttrsToList (
    name: _: "https://${config.ldryt-infra.dns.records.${name}}/"
  ) mediaAdminApps;

  services.prowlarr.settings = {
    auth.required = "DisabledForLocalAddresses";
    server.bindaddress = "127.0.0.1";
  };
  services.sonarr.settings = {
    auth.required = "DisabledForLocalAddresses";
    server.bindaddress = "127.0.0.1";
  };
  services.radarr.settings = {
    auth.required = "DisabledForLocalAddresses";
    server.bindaddress = "127.0.0.1";
  };
}
