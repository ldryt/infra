# nix shell nixpkgs#freerdp -c wlfreerdp /u:docker /p: /v:127.0.0.1:3389 -encryption +clipboard /rfx /gfx:rfx /f /floatbar:sticky:off +gestures +fonts /bpp:32 /audio-mode:0 +aero +window-drag /size:120

{ ... }:
let
  winVersion = "ltsc10";
  dataDir = "/var/lib/windows-dockur/${winVersion}";
in
{
  virtualisation.oci-containers.containers."windows-${winVersion}" = {
    # renovate: datasource=docker depName=ghcr.io/dockur/windows
    image = "ghcr.io/dockur/windows:6.05@sha256:32cc92715a6c5dc1f63142d3be11059279d64d0faa7519618a07290b3076f9f2";
    user = "root:root";
    autoStart = false;
    environment = {
      VERSION = winVersion;
      RAM_SIZE = "6G";
      CPU_CORES = "6";
      DISK_SIZE = "200G";
    };
    ports = [
      "127.0.0.1:8006:8006"
      "127.0.0.1:3389:3389/tcp"
      "127.0.0.1:3389:3389/udp"
    ];
    extraOptions = [
      "--device=/dev/kvm"
      "--device=/dev/net/tun"
      "--cap-add=NET_ADMIN"
      "--cap-add=NET_RAW"
      "--stop-timeout=120"
    ];
    volumes = [ "${dataDir}:/storage" ];
  };
  systemd.tmpfiles.rules = [ "d '${dataDir}' 0755 root root - -" ];
}
