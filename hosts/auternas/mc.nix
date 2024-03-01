{ ... }: {
  environment.etc."auternas-config/FabricProxy-Lite.toml".text = ''
    # this token is revoked by now ;)
    secret = "fc1e42d136281fc011ec38c8ba7af3a48a9a2e3855cccb3a46178a02bbb99a7e"
  '';

  virtualisation.oci-containers.containers = {
    "auternas" = {
      image =
        "ghcr.io/itzg/minecraft-server:java21-graalvm@sha256:759d450f110f69e515846c3b04d143c8cc4f4a79b9bb9e9775c6ff3c9aee0024";
      ports = [ "25565:25565" ];
      volumes = [
        # "/var/lib/auternas-data:/data"
        "/etc/auternas-config/FabricProxy-Lite.toml:/config/FabricProxy-Lite.toml:ro"
      ];
      environment = {
        EULA = "true";
        MEMORY = "";
        JVM_XX_OPTS = "-XX:MaxRAMPercentage=75";
        USE_AIKAR_FLAGS = "true";
        MOTD = "f8916f4a";
        VERSION = "1.20.4";
        TYPE = "fabric";
        MODRINTH_PROJECTS = "fabric-api:9p2sguD7,fabricproxy-lite:Mxw3Cbsk";
        ONLINE_MODE = "false";
        SNOOPER_ENABLED = "false";
      };
    };
  };
}
