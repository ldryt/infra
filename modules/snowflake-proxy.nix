{ lib, ... }:
let
  ports = {
    from = 30000;
    to = 30511;
  };
in
{
  services.snowflake-proxy = {
    enable = true;
    capacity = lib.mkDefault 256;
    extraFlags = [ "-ephemeral-ports-range=${toString ports.from}:${toString ports.to}" ];
  };

  networking.firewall.allowedUDPPortRanges = [ ports ];

  systemd.services.snowflake-proxy.serviceConfig = {
    Restart = "on-failure";
    RestartSec = "5s";
  };
}
