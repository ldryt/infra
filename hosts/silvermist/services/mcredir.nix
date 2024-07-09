{ pkgs, flakePackages, ... }:
let
  mcredirPort = 25565;
  mcredirConfig = pkgs.writeText "mcredirConfig" ''
    listen-address: "0.0.0.0:${toString mcredirPort}"

    mc:
      version: "1.21"
      protocol: 767
      motd: "Click here to start the server."
  '';
in
{
  networking.firewall.allowedTCPPorts = [ mcredirPort ];
  systemd.services.mcredir = {
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${flakePackages.mcredir}/bin/mcredir ${mcredirConfig}";
    };
  };
}
