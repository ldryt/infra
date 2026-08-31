{
  config,
  pkgs,
  ...
}:
let
  mediaDir = "/mnt/media";
  stateDir = "/var/lib/nixarr";

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

  services.prowlarr.settings.auth.required = "DisabledForLocalAddresses";
  services.sonarr.settings.auth.required = "DisabledForLocalAddresses";
  services.radarr.settings.auth.required = "DisabledForLocalAddresses";
}
