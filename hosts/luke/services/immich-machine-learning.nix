{
  config,
  lib,
  pkgs-master,
  ...
}:
let
  common = import ../../common/immich { inherit pkgs-master; };
in
{
  environment.persistence.luke.directories = [
    {
      directory = config.services.immich.machine-learning.environment.MACHINE_LEARNING_CACHE_FOLDER;
      user = "immich";
    }
  ];

  networking.firewall.allowedUDPPorts = [ common.wg.port ];
  networking.firewall.interfaces."${common.wg.int}".allowedTCPPorts = [ common.ml.port ];
  sops.secrets."services/immich/wg/privateKey" = { };
  networking.wireguard.interfaces."${common.wg.int}" = {
    ips = [ "${common.wg.luke.ip}${common.wg.subnet}" ];
    listenPort = common.wg.port;
    privateKeyFile = config.sops.secrets."services/immich/wg/privateKey".path;
    peers = [
      {
        publicKey = common.wg.silvermist.pubKey;
        allowedIPs = [ "${common.wg.silvermist.ip}/32" ];
        endpoint = "silvermist.${config.ldryt-infra.dns.zone}:${toString common.wg.port}";
        persistentKeepalive = 25;
      }
    ];
  };

  # https://github.com/NixOS/nixpkgs/issues/418799
  users.users.immich = {
    home = config.services.immich.machine-learning.environment.MACHINE_LEARNING_CACHE_FOLDER;
    createHome = true;
  };

  systemd.services.immich-server.enable = false;
  services.immich = {
    enable = true;
    package = common.immichPkg;
    database.enable = false;
    redis.enable = false;
    machine-learning = {
      enable = true;
      environment = {
        IMMICH_HOST = lib.mkForce common.wg.luke.ip;
        MACHINE_LEARNING_PRELOAD__CLIP__TEXTUAL = common.ml.clipModel;
        MACHINE_LEARNING_PRELOAD__CLIP__VISUAL = common.ml.clipModel;
        MACHINE_LEARNING_PRELOAD__FACIAL_RECOGNITION__DETECTION = common.ml.facialModel;
        MACHINE_LEARNING_PRELOAD__FACIAL_RECOGNITION__RECOGNITION = common.ml.facialModel;
        MACHINE_LEARNING_PRELOAD__OCR__DETECTION = common.ml.ocrModel;
        MACHINE_LEARNING_PRELOAD__OCR__RECOGNITION = common.ml.ocrModel;
        MACHINE_LEARNING_MODEL_TTL = "-1";
      };
    };
  };
}
