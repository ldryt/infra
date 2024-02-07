{ ... }:
let secrets = ../../../../secrets/git-crypt.nix;
in {
  virtualisation.oci-containers.containers = {
    "ocis" = {
      image =
        "owncloud/ocis@sha256:0275e27d2ffb37ec234c4a27523fa16ab3cdfdc8750318da2cd7c6f29794e8fe";
      entrypoint = "/bin/sh";
      cmd = [ "-c" "ocis server" ];
      environment = {
        OCIS_URL = "https://ocis." + secrets.ldryt.host;
        PROXY_TLS = "false";
        STORAGE_USERS_DRIVER = "s3ng";
        STORAGE_SYSTEM_DRIVER = "ocis";
        STORAGE_USERS_S3NG_ENDPOINT = "blabla";
        STORAGE_USERS_S3NG_ACCESS_KEY = "blabla";
        STORAGE_USERS_S3NG_SECRET_KEY = "blabla";
        STORAGE_USERS_S3NG_BUCKET = "ldryt-ocis";
        PROXY_AUTOPROVISION_ACCOUNTS = "true";
        PROXY_ROLE_ASSIGNMENT_DRIVER = "oidc";
        OCIS_OIDC_ISSUER = "https://iam." + secrets.ldryt.host
          + "/realms/master";
        PROXY_OIDC_REWRITE_WELLKNOWN = "true";
        OCIS_INSECURE = "true";
        IDM_ADMIN_PASSWORD = "blabla";
      };
      volumes = [ "ocis-config:/etc/ocis" "ocis-data:/var/lib/ocis" ];
      ports = [ "9200:9200/tcp" ];
    };
  };
  services.nginx = {
    virtualHosts.${"ocis." + secrets.ldryt.host} = {
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
}
