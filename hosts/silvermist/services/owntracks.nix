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

      autheliaLocation = pkgs.writeText "authelia-location.conf" ''
        ## Virtual endpoint created by nginx to forward auth requests.
        location /internal/authelia/authz {
          ## Essential Proxy Configuration
          internal;
          proxy_pass http://127.0.0.1:44092/api/authz/auth-request;

          ## Headers
          ## The headers starting with X-* are required.
          proxy_set_header X-Original-Method $request_method;
          proxy_set_header X-Original-URL $scheme://$http_host$request_uri;
          proxy_set_header X-Forwarded-For $remote_addr;
          proxy_set_header Content-Length "";
          proxy_set_header Connection "";

          ## Basic Proxy Configuration
          proxy_pass_request_body off;
          proxy_next_upstream error timeout invalid_header http_500 http_502 http_503; # Timeout if the real server is dead
          proxy_redirect http:// $scheme://;
          proxy_http_version 1.1;
          proxy_cache_bypass $cookie_session;
          proxy_no_cache $cookie_session;
          proxy_buffers 4 32k;
          client_body_buffer_size 128k;

          ## Advanced Proxy Configuration
          send_timeout 5m;
          proxy_read_timeout 240;
          proxy_send_timeout 240;
          proxy_connect_timeout 240;
        }
      '';

      autheliaRequest = pkgs.writeText "authelia-authrequest.conf" ''
        auth_request /internal/authelia/authz;

        ## Save the upstream metadata response headers from Authelia to variables.
        auth_request_set $user $upstream_http_remote_user;
        auth_request_set $groups $upstream_http_remote_groups;
        auth_request_set $name $upstream_http_remote_name;
        auth_request_set $email $upstream_http_remote_email;

        ## Inject the metadata response headers from the variables into the request made to the backend.
        proxy_set_header Remote-User $user;
        proxy_set_header Remote-Groups $groups;
        proxy_set_header Remote-Email $email;
        proxy_set_header Remote-Name $name;

        ## Set the $redirection_url to the Location header of the response to the Authz endpoint.
        auth_request_set $redirection_url $upstream_http_location;
        ## When there is a 401 response code from the authz endpoint redirect to the $redirection_url.
        error_page 401 =302 $redirection_url;
      '';
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
