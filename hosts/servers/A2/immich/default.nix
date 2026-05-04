{
  config,
  pkgs-master,
  ...
}:
let
  common = import ../../common/immich;
in
{
  imports = [ "../../common/immich/mounts.nix" ];
  environment.persistence.silvermist.directories = [
    {
      directory = "/var/cache/rclone-vfs-1";
      user = "root";
    }
  ];

  networking.firewall.allowedUDPPorts = [ common.wg.port ];
  sops.secrets."services/immich/wg/privateKey" = { };
  networking.wireguard.interfaces."${common.wg.int}" = {
    ips = [ common.wg.A2.ip ];
    listenPort = common.wg.port;
    privateKeyFile = config.sops.secrets."services/immich/wg/privateKey".path;
    peers = [
      {
        publicKey = common.wg.A1.pubKey;
        allowedIPs = [ common.wg.A1.ip ];
        endpoint = "${common.wg.A1.ip}:${common.wg.port}";
        persistentKeepalive = 25;
      }
    ];
  };

  sops.secrets."services/immich/db/password" = { };
  sops.templates."immich-secrets.env" = {
    owner = "immich";
    content = "DB_PASSWORD=${config.sops.placeholder."services/immich/db/password"}";
  };
  services.immich = {
    enable = true;
    package = pkgs-master.immich;
    mediaLocation = common.dataDir;
    machine-learning.enable = false;
    database = {
      enable = false;
      host = common.wg.A1.ip;
      port = 5432;
    };
    redis = {
      enable = false;
      host = common.wg.A1.ip;
      port = common.redis.port;
    };
    secretsFile = config.sops.templates."immich-secrets.env".path;
    environment = {
      IMMICH_WORKERS_EXCLUDE = "api";
      IMMICH_MACHINE_LEARNING_URL = "http://${common.wg.B1.ip}:${common.ml.port}";
    };
  };
}
