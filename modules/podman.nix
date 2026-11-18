{ config, lib, pkgs, ... }:
{
  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
      autoPrune = {
        enable = true;
        flags = [
          "--all"
          "--volumes"
        ];
      };
    };
    oci-containers.backend = "podman";
  };

  systemd.timers.podman-prune.timerConfig.Persistent = lib.mkForce false;

  networking.firewall.interfaces.${if config.networking.firewall.backend == "nftables" then "podman*" else "podman+"} = {
    allowedTCPPorts = [ 53 ];
    allowedUDPPorts = [ 53 ];
  };

  environment.systemPackages = with pkgs; [
    podman-compose
    podman-tui
  ];
}
