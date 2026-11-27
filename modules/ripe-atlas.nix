{ config, lib, ... }:
let
  inherit (config.users.users.ripe-atlas) home uid;
  runtimeDir = "/run/user/${toString uid}";
  userManager = "user@${toString uid}.service";
in
{
  users.groups.ripe-atlas = { };
  users.users.ripe-atlas = {
    uid = lib.mkDefault 1446;
    isSystemUser = true;
    group = "ripe-atlas";
    home = "/var/lib/ripe-atlas";
    createHome = true;
    homeMode = "0700";
    autoSubUidGidRange = true;
    linger = true;
  };

  ldryt-infra.persist.directories = [
    {
      directory = home;
      user = "ripe-atlas";
      group = "ripe-atlas";
      mode = "0700";
    }
  ];

  ldryt-infra.monitoring.jsonProbes.ripe-atlas = {
    target = "https://atlas.ripe.net/api/v2/probes/1019122/";
    scrapeInterval = "5m";
    metrics = [
      {
        name = "ripe_atlas_status";
        path = "{.status.id}";
        help = "Connection state reported by the RIPE Atlas controller.";
        valuetype = "gauge";
      }
    ];
  };

  virtualisation.oci-containers = {
    backend = "podman";
    containers.ripe-atlas = {
      # renovate: datasource=docker depName=jamesits/ripe-atlas
      image = "docker.io/jamesits/ripe-atlas:5130-probe";
      podman.user = "ripe-atlas";
      networks = [ "pasta" ];
      environment.RXTXRPT = "no";
      capabilities = {
        ALL = false;
        NET_RAW = true;
        KILL = true;
        SETUID = true;
        SETGID = true;
        FOWNER = true;
        CHOWN = true;
        DAC_OVERRIDE = true;
      };
      volumes = [
        "ripe-atlas-etc:/etc/ripe-atlas"
        "ripe-atlas-spool:/var/spool/ripe-atlas"
      ];
      extraOptions = [
        "--tmpfs=/run/ripe-atlas"
        "--memory=256m"
      ];
    };
  };

  systemd.services.podman-ripe-atlas = {
    requires = [ userManager ];
    after = [ userManager ];
    unitConfig.RequiresMountsFor = lib.mkForce "${runtimeDir}/containers ${home}";
    environment.XDG_RUNTIME_DIR = runtimeDir;
    serviceConfig.RestartSec = "10s";
  };
}
