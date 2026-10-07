{ config, ... }:
let
  backupsDir = "/mnt/home-assistant";
in
{
  users.users.colon.extraGroups = [ "dialout" ];
  virtualisation.oci-containers = {
    backend = "podman";
    containers.home-assistant = {
      # renovate: datasource=docker depName=ghcr.io/home-assistant/home-assistant
      image = "ghcr.io/home-assistant/home-assistant:2026.10.0@sha256:1b64d38f38d922bf9d59336451fd6453e1d614f934456af4ee3d2a51061be3a4";
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
