{ config, pkgs-unstable, ... }:
{
  services.minecraft-server = {
    enable = true;
    eula = true;
    openFirewall = true;
    declarative = true;
    package = pkgs-unstable.papermcServers.papermc-1_21;
    jvmOpts = "-XX:MinRAMPercentage=75 -XX:MaxRAMPercentage=75 -XX:+AlwaysPreTouch -XX:+DisableExplicitGC -XX:+ParallelRefProcEnabled -XX:+PerfDisableSharedMem -XX:+UnlockExperimentalVMOptions -XX:+UseG1GC -XX:G1HeapRegionSize=8M -XX:G1HeapWastePercent=5 -XX:G1MaxNewSizePercent=40 -XX:G1MixedGCCountTarget=4 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1NewSizePercent=30 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:G1ReservePercent=20 -XX:InitiatingHeapOccupancyPercent=15 -XX:MaxGCPauseMillis=200 -XX:MaxTenuringThreshold=1 -XX:SurvivorRatio=32 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true";
    serverProperties = {
      max-tick-time = 20000;
      view-distance = 24;
      difficulty = "hard";
    };
  };
  systemd.services.minecraft-server.serviceConfig.RestartSec = "10s";

  ldryt-infra.backups.mc = {
    paths = [ config.services.minecraft-server.dataDir ];
    timerConfig.OnCalendar = "*-*-* *:*/5:00"; # every 5 minutes
  };
}
