{ config, ... }:
let
  workDir = "/mnt/archiveteam/projects";
in
{
  fileSystems."/mnt/archiveteam" = {
    device = "/dev/mapper/archiveteam";
    fsType = "ext4";
    options = [
      "noatime"
      "nodev"
      "nosuid"
      "nofail"
      "x-systemd.device-timeout=30s"
    ];
  };

  virtualisation.oci-containers.containers.archiveteam-warrior = {
    image = "atdr.meo.ws/archiveteam/warrior-dockerfile";
    pull = "newer";
    environment = {
      CONCURRENT_ITEMS = "6";
      DOWNLOADER = "ldryt";
      SELECTED_PROJECT = "auto";
    };
    ports = [ "127.0.0.1:8001:8001" ];
    volumes = [
      "archiveteam-warrior-projects:/home/warrior/projects"
      "${workDir}:/home/warrior/data/projects"
    ];
  };

  systemd.services.podman-archiveteam-warrior.unitConfig.RequiresMountsFor = [ workDir ];

  services.nginx.virtualHosts.${config.ldryt-infra.dns.records.archiveteam} = {
    enableACME = true;
    forceSSL = true;
    extraConfig = "include ${./authelia/nginx-location.conf};";
    locations."/" = {
      proxyPass = "http://127.0.0.1:8001";
      proxyWebsockets = true;
      extraConfig = "include ${./authelia/nginx-authrequest.conf};";
    };
  };
}
