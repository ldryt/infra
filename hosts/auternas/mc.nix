{ ... }: {
  environment.etc."auternas-config/FabricProxy-Lite.toml".text = ''
    # this token is revoked by now ;)
    secret = "fc1e42d136281fc011ec38c8ba7af3a48a9a2e3855cccb3a46178a02bbb99a7e"
  '';

  virtualisation.oci-containers.containers = {
    "auternas" = {
      image =
        "ghcr.io/itzg/minecraft-server@sha256:2adc322f52549917a99f0d6e851c2e3d5893dd5f4a38e9e2420c5cbee486a476";
      ports = [ "25565:25565" ];
      volumes = [
        "auternas-data:/data"
        "/etc/auternas-config/FabricProxy-Lite.toml:/config/FabricProxy-Lite.toml:ro"
      ];
      environment = {
        EULA = "true";
        MEMORY = "6G";
        USE_AIKAR_FLAGS = "true";
        VERSION = "1.20.4";
        TYPE = "fabric";
        MODRINTH_PROJECTS = "fabric-api:9p2sguD7,fabricproxy-lite:Mxw3Cbsk";
        ONLINE_MODE = "false";
      };
    };
  };
}
