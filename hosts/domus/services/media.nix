{
  config,
  lib,
  pkgs,
  ...
}:
let
  mediaDir = "/mnt/media";
  stateDir = "/var/lib/nixarr";
  torrentDir = "/var/lib/rclone/cache/torrent-staging";
  qbittorrentApi = {
    host = "192.168.15.1";
    port = config.nixarr.qbittorrent.webuiPort;
  };
  mediaAdminApps = {
    radarr = {
      host = "127.0.0.1";
      port = config.services.radarr.settings.server.port;
    };
    sonarr = {
      host = "127.0.0.1";
      port = config.services.sonarr.settings.server.port;
    };
    prowlarr = {
      host = "127.0.0.1";
      port = config.services.prowlarr.settings.server.port;
    };
    qbittorrent = qbittorrentApi;
  };

  seerrOidc = pkgs.seerr.overrideAttrs (final: old: {
    version = "preview-new-oidc-${builtins.substring 0 7 final.src.rev}";
    src = pkgs.fetchFromGitHub {
      owner = "michaelhthomas";
      repo = "seerr";
      rev = "2e523125e8e7262af44309c70db20fe2d7ca28a3";
      hash = "sha256-k8qWhsSBnQXfGk/xEmb2+4tlw6xY8viwWzEQUBxtrNs=";
    };
    pnpmDeps = old.pnpmDeps.overrideAttrs {
      outputHash = "sha256-bfdmNLBypcoJ79/lMRSgRKSIddQJJohcn3/dL21edog=";
    };
  });

  jellyfinSso = pkgs.fetchzip rec {
    # renovate: datasource=github-releases depName=Buco7854/jellyfin-plugin-sso extractVersion=^v(?<version>4[.][0-9.]+)$
    version = "4.0.0.7";
    pname = "jellyfin-plugin-sso";
    url = "https://github.com/Buco7854/jellyfin-plugin-sso/releases/download/v${version}/sso-authentication_${version}.zip";
    hash = "sha256-oG3Ho3E3ejD9KOLxs8SUHiRG8EjEycaQ7klpldke/5g=";
    stripRoot = false;
  };
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
        mediaServerType = 4; # NOT_CONFIGURED
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

  ldryt-infra.rclone.mounts.media = {
    mountPoint = mediaDir;
    group = "media";
    umask = "0002";
  };

  systemd.tmpfiles.rules = [
    "d ${mediaDir} 2775 root media -"
    "d ${torrentDir} 2775 qbittorrent media -"
  ];
  systemd.services.radarr.unitConfig.RequiresMountsFor = [ mediaDir ];
  systemd.services.sonarr.unitConfig.RequiresMountsFor = [ mediaDir ];
  systemd.services.qbittorrent = {
    unitConfig.RequiresMountsFor = [ torrentDir mediaDir ];
    serviceConfig.ReadOnlyPaths = [ mediaDir ];
    serviceConfig.ReadWritePaths = [ "${mediaDir}/qbittorrent" ];
  };

  systemd.services.radarr-sync-config = {
    requires = [ "radarr-api.service" "qbittorrent.service" ];
    after = [ "qbittorrent.service" ];
  };
  systemd.services.sonarr-sync-config = {
    requires = [ "sonarr-api.service" "qbittorrent.service" ];
    after = [ "qbittorrent.service" ];
  };
  systemd.services.prowlarr-sync-config.requires = [
    "prowlarr-api.service"
    "radarr-api.service"
    "sonarr-api.service"
  ];

  nixarr = {
    enable = true;
    inherit mediaDir stateDir;

    vpn = {
      enable = true;
      wgConf = config.sops.secrets."services/media/vpn/wg-media.conf".path;
      exposeOnLAN = false;
      proxyListenAddr = "127.0.0.1";
    };

    qbittorrent = {
      enable = true;
      vpn.enable = true;
      qui.enable = false;
      peerPort = 39656;
      torrentQueueing.enable = false;
      extraConfig.Preferences = {
        "Downloads\\TempPath" = torrentDir;
        "Downloads\\ScanDirsV2" = "{}";
        "Downloads\\PreAllocation" = false;
      };
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
      settings-sync.downloadClients = [
        {
          enable = true;
          name = "qBittorrent";
          implementation = "QBittorrent";
          remove_completed_downloads = false;
          fields = {
            inherit (qbittorrentApi) host port;
            tvCategory = "sonarr";
          };
        }
      ];
    };

    radarr = {
      enable = true;
      settings-sync.downloadClients = [
        {
          enable = true;
          name = "qBittorrent";
          implementation = "QBittorrent";
          remove_completed_downloads = false;
          fields = {
            inherit (qbittorrentApi) host port;
            movieCategory = "radarr";
          };
        }
      ];
    };
  };

  vpnNamespaces.wg.portMappings = lib.mkAfter [
    {
      from = config.nixarr.qbittorrent.webuiPort;
      to = config.nixarr.qbittorrent.webuiPort;
    }
  ];

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
    unitConfig.RequiresMountsFor = [ mediaDir ];
    serviceConfig.ExecStartPre = [
      (pkgs.writeShellScript "install-jellyfin-sso" ''
        set -eu
        data_dir=${stateDir}/jellyfin/data
        if test -d "$data_dir/plugins/flowfin"; then
          mkdir -p "$data_dir/sso-migration-backups"
          backup=$(${pkgs.coreutils}/bin/mktemp -d "$data_dir/sso-migration-backups/flowfin.XXXXXX")
          mv "$data_dir/plugins/flowfin" "$backup/"
        fi
        mkdir -p "$data_dir/plugins/buco-sso"
        cp -r --no-preserve=mode ${jellyfinSso}/. "$data_dir/plugins/buco-sso/"
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
    name: app:
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
          proxy_ssl_verify_depth 2;
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
        proxyPass = "http://${app.host}:${toString app.port}";
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
    auth.method = "External";
    auth.required = "DisabledForLocalAddresses";
    server.bindaddress = "127.0.0.1";
  };
  services.sonarr.settings = {
    auth.method = "External";
    auth.required = "DisabledForLocalAddresses";
    server.bindaddress = "127.0.0.1";
  };
  services.radarr.settings = {
    auth.method = "External";
    auth.required = "DisabledForLocalAddresses";
    server.bindaddress = "127.0.0.1";
  };
}
