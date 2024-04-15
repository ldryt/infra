# https://github.com/dockur/windows/issues/261

# RDP access: nix run nixpkgs#rdesktop -- -u docker 127.0.0.1:3389
# WEB access: http://127.0.0.1:8006/
{ ... }:
let
  winVersion = "ltsc10";
  dataDir = "/var/lib/windows-dockur/${winVersion}";
in
{
  virtualisation.oci-containers.containers."windows-${winVersion}" = {
    image = "ghcr.io/dockur/windows:2.10@sha256:8d5918162e2ecc5da08c611676ecf958f96b35ba7e45bdb2a0774641d94c07f0";
    user = "root:root";
    autoStart = false; # start it when needed with `sudo systemctl start podman-windows.service`
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
