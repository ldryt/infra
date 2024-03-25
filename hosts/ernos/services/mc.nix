{ config, lib, pkgs, vars, ... }:
let
  mc.plugins.voicechat = pkgs.fetchurl {
    url =
      "https://cdn.modrinth.com/data/9eGKb6K1/versions/aiI5iPUK/voicechat-bukkit-2.5.9.jar";
    hash = "sha256-UJ3kyCARZcMKk/GSJnOO1gP1rmP60Ix6bw9e3MqWfB4=";
  };
in {
  system.activationScripts."initMCPlugins" = lib.stringAfter [ "var" ] ''
    mkdir -p ${config.services.minecraft-server.dataDir}/plugins
    ln -sf ${mc.plugins.voicechat} ${config.services.minecraft-server.dataDir}/plugins/voicechat.jar
    chown -R minecraft:minecraft ${config.services.minecraft-server.dataDir}/plugins
  '';

  services.minecraft-server = {
    enable = true;
    eula = true;
    openFirewall = true;
    declarative = true;
    package = pkgs.papermc;
    jvmOpts =
      "-XX:MinRAMPercentage=75 -XX:MaxRAMPercentage=75 -XX:+AlwaysPreTouch -XX:+DisableExplicitGC -XX:+ParallelRefProcEnabled -XX:+PerfDisableSharedMem -XX:+UnlockExperimentalVMOptions -XX:+UseG1GC -XX:G1HeapRegionSize=8M -XX:G1HeapWastePercent=5 -XX:G1MaxNewSizePercent=40 -XX:G1MixedGCCountTarget=4 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1NewSizePercent=30 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:G1ReservePercent=20 -XX:InitiatingHeapOccupancyPercent=15 -XX:MaxGCPauseMillis=200 -XX:MaxTenuringThreshold=1 -XX:SurvivorRatio=32 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true";
    serverProperties = {
      max-tick-time = 20000;
      view-distance = 24;
      difficulty = "hard";
    };
  };
  networking.firewall.allowedUDPPorts = [ 24454 ];
  systemd.services.minecraft-server.serviceConfig.RestartSec = "10s";

  sops.secrets."backups/restic/repositoryPass" = { };
  sops.secrets."backups/restic/sshKey" = { };
  services.restic.backups.mc = {
    paths = [ config.services.minecraft-server.dataDir ];
    repository = "sftp:${
        vars.sensitive.backups.user + "@" + vars.sensitive.backups.host
      }:restic-repo-mc";
    extraOptions = [
      "sftp.command='ssh ${
        vars.sensitive.backups.user + "@" + vars.sensitive.backups.host
      } -p 23 -i ${
        config.sops.secrets."backups/restic/sshKey".path
      } -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -s sftp'"
    ];
    initialize = true;
    passwordFile = config.sops.secrets."backups/restic/repositoryPass".path;
    pruneOpts = [
      "--keep-hourly 12"
      "--keep-daily 7"
      "--keep-weekly 8"
      "--keep-monthly 12"
      "--keep-yearly 100"
    ];
    timerConfig = {
      OnCalendar = "hourly";
      RandomizedDelaySec = "15m";
      Persistent = true;
    };
  };
}
