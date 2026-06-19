{ config, ... }:
let
  port = 44848;
  dataDir = "/var/lib/wallabag";
  baseUid = 44800000;
  nobodyUid = 65534;
  mappedNobodyUid = toString (baseUid + nobodyUid);
in
{
  ldryt-infra.persist.directories = [
    {
      directory = dataDir;
      mode = "0755";
    }
  ];

  systemd.tmpfiles.rules = [
    "d ${dataDir}/data 0755 ${mappedNobodyUid} ${mappedNobodyUid} - -"
    "Z ${dataDir}/data - ${mappedNobodyUid} ${mappedNobodyUid} - -"
    "d ${dataDir}/images 0755 ${mappedNobodyUid} ${mappedNobodyUid} - -"
    "Z ${dataDir}/images - ${mappedNobodyUid} ${mappedNobodyUid} - -"
  ];

  sops.secrets."services/wallabag/env" = { };
  virtualisation.oci-containers.containers.wallabag = {
    image = "docker.io/wallabag/wallabag:2.6.14@sha256:4a527e027e0d59e87c14225ef11e005af3d4890374202ad319ce5e63dfc66709";
    ports = [ "127.0.0.1:${toString port}:80" ];
    environment = {
      SYMFONY__ENV__DOMAIN_NAME = "https://${config.ldryt-infra.dns.records.wallabag}";
      SYMFONY__ENV__DATABASE_DRIVER = "pdo_sqlite";
      SYMFONY__ENV__FOSUSER_REGISTRATION = "false";
    };
    environmentFiles = [
      config.sops.secrets."services/wallabag/env".path
    ];
    volumes = [
      "${dataDir}/data:/var/www/wallabag/data"
      "${dataDir}/images:/var/www/wallabag/web/assets/images"
    ];
    extraOptions = [
      "--uidmap=0:${toString baseUid}:65536"
      "--gidmap=0:${toString baseUid}:65536"
      "--security-opt=no-new-privileges=true"
      "--cap-drop=ALL"
      "--cap-add=CHOWN"
      "--cap-add=SETUID"
      "--cap-add=SETGID"
      "--cap-add=DAC_OVERRIDE" # root overwrite files owned by others
      "--cap-add=NET_BIND_SERVICE" # internal nginx port 80
    ];
  };
  systemd.services."podman-wallabag".serviceConfig = {
    IPAddressDeny = [
      "10.0.0.0/8"
      "172.16.0.0/12"
      "192.168.0.0/16"
    ];
    IPAddressAllow = [
      "10.88.0.0/16"
    ];
  };

  services.nginx.virtualHosts."${config.ldryt-infra.dns.records.wallabag}" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString port}";
      proxyWebsockets = true;
      extraConfig = ''
        client_max_body_size 500M;
      '';
    };
  };

  ldryt-infra.monitoring.blackbox.targets = {
    http_ok = [
      "http://${config.ldryt-infra.dns.records.wallabag}/"
    ];
  };

  sops.secrets."backups/restic/repos/wallabag/password" = { };
  ldryt-infra.backups.repos.wallabag = {
    passwordFile = config.sops.secrets."backups/restic/repos/wallabag/password".path;
    paths = [
      dataDir
    ];
  };
}
