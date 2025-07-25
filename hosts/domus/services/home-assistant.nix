{ config, ... }:
let
  backupsDir = "/mnt/home-assistant";
in
{
  users.users.colon.extraGroups = [ "dialout" ];
  virtualisation.oci-containers = {
    backend = "podman";
    containers.home-assistant = {
      image = "ghcr.io/home-assistant/home-assistant:2025.3.3";
      environment.TZ = "Europe/Paris";
      volumes = [
        "home-assistant:/config"
        "${backupsDir}:/config/backups"
      ];
      ports = [ "0.0.0.0:8123:8123" ];
      extraOptions = [
        "--device=/dev/serial/by-id/usb-1a86_USB_Serial-if00-port0:/dev/serial/by-id/usb-1a86_USB_Serial-if00-port0"
      ];
    };
  };
  systemd.services."podman-home-assistant".serviceConfig.RestartSec = "15s";

  sops.secrets."backups/restic/repos/home-assistant/password" = { };
  ldryt-infra.backups.repos.home-assistant = {
    passwordFile = config.sops.secrets."backups/restic/repos/home-assistant/password".path;
    paths = [ backupsDir ];
  };
}
