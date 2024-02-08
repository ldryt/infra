{ config, ... }:
let secrets = import ../../../secrets/obfuscated.nix;
in {
  virtualisation.oci-containers.containers = {
    "ocis" = {
      image =
        "owncloud/ocis@sha256:0275e27d2ffb37ec234c4a27523fa16ab3cdfdc8750318da2cd7c6f29794e8fe";
      entrypoint = "/bin/sh";
      cmd = [ "-c" "ocis init | true; ocis server" ];
      environment = {
        OCIS_URL = "https://files.${secrets.ldryt.host}";
        OCIS_LOG_LEVEL = "info";
        OCIS_LOG_COLOR = "true";

        STORAGE_USERS_DRIVER = "s3ng";
        STORAGE_SYSTEM_DRIVER = "ocis";

        PROXY_TLS = "false";
        OCIS_INSECURE = "false";
        PROXY_AUTOPROVISION_ACCOUNTS = "true";
        PROXY_ROLE_ASSIGNMENT_DRIVER = "oidc";
        OCIS_OIDC_ISSUER = "https://iam.${secrets.ldryt.host}";
        PROXY_OIDC_REWRITE_WELLKNOWN = "true";
        WEB_OIDC_CLIENT_ID = "ocis-web";
        WEB_OIDC_SCOPE = "openid profile groups email";
      };
      environmentFiles = [ config.sops.secrets."ocis/secret_envs".path ];
      volumes = [ "ocis-config:/etc/ocis" "ocis-data:/var/lib/ocis" ];
      ports = [ "9200:9200" ];
    };
  };

  services.nginx = {
    virtualHosts."files.${secrets.ldryt.host}" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        recommendedProxySettings = true;
        proxyPass = "http://127.0.0.1:9200";
        extraConfig = ''
          proxy_buffers 4 256k;
          proxy_buffer_size 128k;
          proxy_busy_buffers_size 256k;

          client_max_body_size 0;
        '';
      };
    };
  };

  services.authelia.instances."ldryt".settings.identity_providers.oidc.clients =
    [
      {
        description = "ownCloud Web";
        id = "ocis-web";
        public = true;
        consent_mode = "implicit";
        scopes = [ "email" "groups" "openid" "profile" ];
        redirect_uris = [
          "https://ocis.${secrets.ldryt.host}/"
          "https://ocis.${secrets.ldryt.host}/oidc-callback.html"
          "https://ocis.${secrets.ldryt.host}/oidc-silent-redirect.html"
        ];
      }
      {
        description = "ownCloud Desktop";
        id = "xdXOt13JKxym1B1QcEncf2XDkLAexMBFwiT9j6EfhhHFJhs2KM9jbjTmf8JBXE69";
        secret =
          "UBntmLjC2yYCeHwsyj73Uwo9TAaecAetRwMw0xYcvNL9yRdLSUi0hUAHfvCHFeFh";
        consent_mode = "implicit";
        scopes = [ "email" "groups" "openid" "profile" "offline_access" ];
        redirect_uris = [ "http://127.0.0.1" "http://localhost" ];
        grant_types = [ "refresh_token" "authorization_code" ];
      }
      {
        description = "ownCloud Android";
        id = "e4rAsNUSIUs0lF4nbv9FmCeUkTlV9GdgTLDH1b5uie7syb90SzEVrbN7HIpmWJeD";
        secret =
          "dInFYGV33xKzhbRmpqQltYNdfLdJIfJ9L5ISoKhNoT9qZftpdWSP71VrpGR9pmoD";
        consent_mode = "implicit";
        scopes = [ "email" "groups" "openid" "profile" "offline_access" ];
        redirect_uris = [ "oc://android.owncloud.com" ];
        grant_types = [ "refresh_token" "authorization_code" ];
      }
      {
        description = "ownCloud iOS";
        id = "mxd5OQDk6es5LzOzRvidJNfXLUZS2oN3oUFeXPP8LpPrhx3UroJFduGEYIBOxkY1";
        secret =
          "KFeFWWEZO9TkisIQzR3fo7hfiMXlOpaqP8CFuTbSHzV1TUuGECglPxpiVKJfOXIx";
        consent_mode = "implicit";
        scopes = [ "email" "groups" "openid" "profile" "offline_access" ];
        redirect_uris = [ "oc://ios.owncloud.com" "oc.ios://ios.owncloud.com" ];
        grant_types = [ "refresh_token" "authorization_code" ];
      }
    ];
}
