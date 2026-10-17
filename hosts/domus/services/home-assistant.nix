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
      image = "ghcr.io/home-assistant/home-assistant:2026.10.2@sha256:33afb0659d786213264c2211f8d91c5fe87461c56eba6a3a546eb05fc71e89f4";
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
