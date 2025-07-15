{ lib, ... }:
{
  virtualisation.docker.enable = true;

  # https://discourse.nixos.org/t/disable-a-systemd-service-while-having-it-in-nixoss-conf/12732/4
  systemd.services.docker.wantedBy = lib.mkForce [ ];
}
