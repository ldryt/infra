{
  config,
  lib,
  pkgs-master,
  ...
}:
let
  common = import ../../common/immich;
in
{
  environment.persistence.silvermist.directories = [
    {
      directory = config.services.immich.machine-learning.environment.MACHINE_LEARNING_CACHE_FOLDER;
      user = "immich";
    }
  ];

  networking.firewall.allowedUDPPorts = [ common.wg.port ];
  networking.firewall.interfaces."${common.wg.int}".allowedTCPPorts = [ common.ml.port ];
  sops.secrets."services/immich/wg/privateKey" = { };
  networking.wireguard.interfaces."${common.wg.int}" = {
    ips = [ common.wg.B1.ip ];
    listenPort = common.wg.port;
    privateKeyFile = config.sops.secrets."services/immich/wg/privateKey".path;
    peers = [
      {
        publicKey = common.wg.A1.pubKey;
        allowedIPs = [ common.wg.A1.ip ];
        endpoint = "${common.wg.A1.ip}:${toString common.wg.port}";
        persistentKeepalive = 25;
      }
    ];
  };

  users.users.immich = {
    home = config.services.immich.machine-learning.environment.MACHINE_LEARNING_CACHE_FOLDER;
    createHome = true;
  };

  systemd.services.immich-server.enable = false;
  services.immich = {
    enable = true;
    package = pkgs-master.immich;
    database.enable = false;
    redis.enable = false;

    machine-learning = {
      enable = true;
      environment = {
        IMMICH_HOST = lib.mkForce common.wg.A1.ip;
        MACHINE_LEARNING_PRELOAD__CLIP__TEXTUAL = common.ml.model;
      };
    };
  };
}
