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
    image = "docker.io/dockurr/windows:latest";
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
    ];
    volumes = [ "${dataDir}:/storage" ];
  };
  systemd.tmpfiles.rules = [ "d '${dataDir}' 0700 root root - -" ];
}
