{ config, pkgs, ... }:
let
  hidden = import ../../../secrets/obfuscated.nix;
  velocitySubdomain = "mc";
  velocityJar = pkgs.fetchurl {
    url =
      "https://api.papermc.io/v2/projects/velocity/versions/3.3.0-SNAPSHOT/builds/363/downloads/velocity-3.3.0-SNAPSHOT-363.jar";
    sha256 = "a5f958608eb890fa12dc16c492fa06122a0219c6696a1f17f405b972fce2dd00";
  };
  velocityConfigFile = pkgs.writeText "velocity-config.toml" ''
    config-version = "2.6"
    bind = "0.0.0.0:25577"
    motd = "<b><red>Main server is unreachable.</red></b>"
    show-max-players = 44
    online-mode = true
    force-key-authentication = true
    prevent-client-proxy-connections = false
    player-info-forwarding-mode = "modern"
    forwarding-secret-file = "velocity.secret"
    announce-forge = false
    kick-existing-players = true
    ping-passthrough = "all"
    enable-player-address-logging = true

    [servers]
    main = "${hidden.mc.main.IP}:25565"
    try = [ "main" ]

    [forced-hosts]
    "${velocitySubdomain}.${hidden.ldryt.host}" = [ "main" ]

    [advanced]
    compression-threshold = 256
    compression-level = 8
    login-ratelimit = 2000
    connection-timeout = 1500
    read-timeout = 10000
    haproxy-protocol = false
    tcp-fast-open = true
    bungee-plugin-message-channel = true
    show-ping-requests = true
    failover-on-unexpected-server-disconnect = true
    announce-proxy-commands = true
    log-command-executions = true
    log-player-connections = true
  '';
in {
  virtualisation.oci-containers.containers = {
    "velocity" = {
      image =
        "docker.io/library/eclipse-temurin:21-jdk@sha256:b1a93e74b7ebce1735d119a45ea17b3cddddfd115a820cde8422b0597e1b5bc9";
      entrypoint = "java";
      cmd = [
        "-Xms128M"
        "-Xmx256M"
        "-XX:+UseG1GC"
        "-XX:G1HeapRegionSize=4M"
        "-XX:+UnlockExperimentalVMOptions"
        "-XX:+ParallelRefProcEnabled"
        "-XX:+AlwaysPreTouch"
        "-XX:MaxInlineLevel=15"
        "-jar"
        "velocity.jar"
      ];
      ports = [ "0.0.0.0:25565:25577" ];
      volumes = [
        "${velocityConfigFile}:/velocity.toml:ro"
        "${velocityJar}:/velocity.jar:ro"
        "${
          config.sops.secrets."services/velocity/forwardingSecret".path
        }:/velocity.secret:ro"
        "/dev/null:/plugins/bStats/config.txt"
      ];
    };
  };
}
