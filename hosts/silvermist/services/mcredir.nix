{ pkgs, config, ... }:
let
  FQDNRegex = builtins.replaceStrings [ "." ] [ ''\.'' ] config.ldryt-infra.dns.records.mcredir;
  mcpulsePorts = {
    slp = 25565;
    pulser = 9065;
  };
  mcpulseConfig = pkgs.writeText "mcpulseConfig" ''
    slp:
      listen-address: "0.0.0.0:${toString mcpulsePorts.slp}"
      version:
        name: "1.21"
        protocol: 767
      motd: "Click here to start the server"

    pulser:
      listen-address: "0.0.0.0:${toString mcpulsePorts.pulser}"
  '';
in
{
  networking.firewall.allowedTCPPorts = [ mcpulsePorts.slp ];
  systemd.services.mcpulse = {
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.mcpulse}/bin/mcpulse -config=${mcpulseConfig}";
    };
  };

  environment.etc."fail2ban/filter.d/mcscan.conf".text = ''
    [Definition]
    failregex = ^.*Handshaked with <HOST>:\d.*Address: (?!${FQDNRegex}).*$
    journalmatch = _SYSTEMD_UNIT=mcpulse.service
    ignoreregex =
  '';
  services.fail2ban.jails."mcscan".settings = {
    filter = "mcscan";
    backend = "systemd";
  };
}
