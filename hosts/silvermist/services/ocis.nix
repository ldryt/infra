{ config, pkgs, ... }:
let
  dns = builtins.fromJSON (builtins.readFile ../dns.json);
  dataDir = "/mnt/ocis-data";
  internalPort = "44082";
in
{
  sops.secrets."services/ocis/secretsConfig".owner = config.users.users.colon.name;

  virtualisation.oci-containers.containers = {
    "ocis" = {
      image = "docker.io/owncloud/ocis:5.0.4-linux-amd64@sha256:0d88f235d039ed71a26a44f24e8785e66e4425b441f18bf895f9b02e9e839d0c"; # https://hub.docker.com/layers/owncloud/ocis/5.0.4-linux-amd64/images/sha256-0d88f235d039ed71a26a44f24e8785e66e4425b441f18bf895f9b02e9e839d0c?context=explore
      entrypoint = "/bin/sh";
      cmd = [
        "-c"
        "ocis server"
      ];
      environment = {
        PROXY_HTTP_ADDR = "0.0.0.0:9200";
        OCIS_URL = "https://${dns.subdomains.ocis}.${dns.zone}";

        OCIS_OIDC_ISSUER = "https://${dns.subdomains.keycloak}.${dns.zone}/realms/master";
        WEB_OIDC_CLIENT_ID = "ocis-web";
        PROXY_TLS = "false";
        PROXY_AUTOPROVISION_ACCOUNTS = "true";
        PROXY_USER_OIDC_CLAIM = "preferred_username";
        PROXY_USER_CS3_CLAIM = "username";
        # PROXY_ROLE_ASSIGNMENT_DRIVER = "oidc";
        PROXY_OIDC_REWRITE_WELLKNOWN = "true";
      };
      # secretsConfig contains all the secrets needed by ocis (generated by "ocis init")
      volumes = [
        "${dataDir}:/var/lib/ocis"
        "${config.sops.secrets."services/ocis/secretsConfig".path}:/etc/ocis/ocis.yaml:ro"
      ];
      ports = [ "127.0.0.1:${internalPort}:9200" ];
    };
  };

  sops.secrets."system/smb/glouton/ocis-data/credentials" = { };
  environment.systemPackages = [ pkgs.cifs-utils ];
  fileSystems."${dataDir}" = {
    device = "//u391790-sub2.your-storagebox.de/u391790-sub2";
    fsType = "cifs";
    options = [
      "async,rw,auto,nofail,credentials=${
        config.sops.secrets."system/smb/glouton/ocis-data/credentials".path
      },uid=${toString config.users.users.colon.uid},cache=loose,fsc,sfu,mfsymlinks"
    ];
  };

  services.nginx.virtualHosts."${dns.subdomains.ocis}.${dns.zone}" = {
    enableACME = true;
    forceSSL = true;
    kTLS = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${internalPort}";
      extraConfig = ''
        client_max_body_size 0;
      '';
    };
  };

  ldryt-infra.backups.ocis = {
    paths = [ dataDir ];
  };
}