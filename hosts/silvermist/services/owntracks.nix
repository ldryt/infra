{ config, pkgs, ... }:
let
  recorderPort = 4073;
  recorderStateDir = "/var/lib/owntracks-recorder";
  mqttInternalPort = 1883;
  mqttProxiedPort = 1884;
in
{
  sops.secrets."backups/restic/repos/owntracks/password" = { };
  ldryt-infra.backups.repos.owntracks = {
    passwordFile = config.sops.secrets."backups/restic/repos/owntracks/password".path;
    paths = [ recorderStateDir ];
  };

  environment.persistence.silvermist.directories = [
    {
      directory = "/var/lib/${config.systemd.services.owntracks-recorder.serviceConfig.StateDirectory}";
      user = "owntracks";
    }
  ];

  sops.secrets."services/owntracks/mqtt_internal_passwords" = {
    owner = "mosquitto";
    group = "mosquitto";
    restartUnits = [ "mosquitto.service" ];
  };
  sops.secrets."services/owntracks/mqtt_mobile_passwords" = {
    owner = "mosquitto";
    group = "mosquitto";
    restartUnits = [ "mosquitto.service" ];
  };
  systemd.services.mosquitto.serviceConfig.ReadOnlyPaths = [
    "-${config.sops.secrets."services/owntracks/mqtt_internal_passwords".path}"
    "-${config.sops.secrets."services/owntracks/mqtt_mobile_passwords".path}"
  ];
  environment.etc = {
    "mosquitto-acls/internal.acl".text = ''
      pattern readwrite #
    '';
    "mosquitto-acls/mobile.acl".text = ''
      pattern readwrite owntracks/%u/#
      pattern read owntracks/#
    '';
    "mosquitto-conf.d/10-owntracks-listeners.conf".text = ''
      listener ${toString mqttInternalPort} 127.0.0.1
      allow_anonymous false
      password_file ${config.sops.secrets."services/owntracks/mqtt_internal_passwords".path}
      acl_file /etc/mosquitto-acls/internal.acl

      listener ${toString mqttProxiedPort} 127.0.0.1
      protocol websockets
      allow_anonymous false
      password_file ${config.sops.secrets."services/owntracks/mqtt_mobile_passwords".path}
      acl_file /etc/mosquitto-acls/mobile.acl
    '';
  };
  services.mosquitto = {
    enable = true;
    includeDirs = [ "/etc/mosquitto-conf.d" ];
  };

  users.users.owntracks = {
    isSystemUser = true;
    group = "owntracks";
  };
  users.groups.owntracks = { };
  sops.secrets."services/owntracks/recorder_env" = {
    owner = "owntracks";
    group = "owntracks";
  };
  systemd.services.owntracks-recorder = {
    description = "OwnTracks Recorder";
    after = [
      "network.target"
      "mosquitto.service"
    ];
    requires = [ "mosquitto.service" ];
    wantedBy = [ "multi-user.target" ];
    environment = {
      OTR_HTTPPORT = toString recorderPort;
      OTR_HTTPHOST = "127.0.0.1";
      OTR_HOST = "127.0.0.1";
      OTR_PORT = toString mqttInternalPort;
      OTR_STORAGEDIR = recorderStateDir;
      OTR_DOCROOT = "${pkgs.owntracks-recorder}/htdocs";
    };
    serviceConfig = {
      Type = "simple";
      User = "owntracks";
      Group = "owntracks";
      StateDirectory = baseNameOf recorderStateDir;
      # OTR_USER ; OTR_PASS
      EnvironmentFile = config.sops.secrets."services/owntracks/recorder_env".path;
      ExecStart = "${pkgs.owntracks-recorder}/bin/ot-recorder 'owntracks/#'";
      Restart = "always";
      RestartSec = "10s";
    };
  };

  services.nginx.virtualHosts."${config.ldryt-infra.dns.records.owntracks}" =
    let
      owntracks-frontend = pkgs.stdenv.mkDerivation {
        pname = "owntracks-frontend";
        version = "v2.15.3";
        src = pkgs.fetchzip {
          url = "https://github.com/owntracks/frontend/releases/download/v2.15.3/v2.15.3-dist.zip";
          sha256 = "sha256-iy+yISPcOD/2lTyJUb1eI3wufLku1mKfVDm0+Dy8OKk=";
        };
        configJs = pkgs.writeText "config.js" ''
          window.owntracks = window.owntracks || {};
          window.owntracks.config = {
            api: {
              baseUrl: "https://${config.ldryt-infra.dns.records.owntracks}"
            },
            router: {
              basePath: ""
            }
          };
        '';
        installPhase = ''
          runHook preInstall
          mkdir -p $out
          cp -r ./* $out/
          cp $configJs $out/config/config.js
          runHook postInstall
        '';
      };

      autheliaLocation = ./authelia/nginx-location.conf;
      autheliaRequest = ./authelia/nginx-authrequest.conf;
    in
    {
      enableACME = true;
      forceSSL = true;
      kTLS = true;
      extraConfig = "include ${autheliaLocation};";

      locations = {
        # SPA frontend
        "/" = {
          root = "${owntracks-frontend}";
          tryFiles = "$uri $uri/ /index.html";
          extraConfig = ''
            include ${autheliaRequest};
          '';
        };

        # Recorder backend
        "/api/" = {
          proxyPass = "http://127.0.0.1:${toString recorderPort}";
          extraConfig = ''
            include ${autheliaRequest};
            proxy_set_header X-Limit-U $user;
          '';
        };

        # Recorder backend websockets
        "/ws" = {
          proxyPass = "http://127.0.0.1:${toString recorderPort}";
          proxyWebsockets = true;
          extraConfig = ''
            include ${autheliaRequest};
            proxy_set_header X-Limit-U $user;
          '';
        };

        # MQTT for mobile apps
        "/mqtt" = {
          proxyPass = "http://127.0.0.1:${toString mqttProxiedPort}";
          proxyWebsockets = true;
          extraConfig = ''
            auth_request off;

            proxy_set_header Host $host;
            proxy_read_timeout 3600s;
            proxy_send_timeout 3600s;
          '';
        };
      };
    };
}
