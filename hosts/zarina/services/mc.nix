{
  config,
  lib,
  pkgs,
  ...
}:
let
  mc.plugins.voicechat = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/9eGKb6K1/versions/AyVUPPCX/voicechat-bukkit-2.5.15.jar";
    hash = "sha256-TVGNUeo9FfRnoNiiZkl8UuiLjNcjzXzO+qM9xBKJChg=";
  };
in
{
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
    package = pkgs.papermcServers.papermc-1_20_4;
    jvmOpts = "-XX:MinRAMPercentage=40 -XX:MaxRAMPercentage=60 -XX:+AlwaysPreTouch -XX:+DisableExplicitGC -XX:+ParallelRefProcEnabled -XX:+PerfDisableSharedMem -XX:+UnlockExperimentalVMOptions -XX:+UseG1GC -XX:G1HeapRegionSize=8M -XX:G1HeapWastePercent=5 -XX:G1MaxNewSizePercent=40 -XX:G1MixedGCCountTarget=4 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1NewSizePercent=30 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:G1ReservePercent=20 -XX:InitiatingHeapOccupancyPercent=15 -XX:MaxGCPauseMillis=200 -XX:MaxTenuringThreshold=1 -XX:SurvivorRatio=32 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true";
    serverProperties = {
      max-tick-time = 20000;
      view-distance = 24;
      difficulty = "hard";
    };
  };
  networking.firewall.allowedUDPPorts = [ 24454 ];
  systemd.services.minecraft-server.serviceConfig.RestartSec = "10s";
}
