{ config, pkgs, ... }:
let
  silvermistDNS = builtins.fromJSON (builtins.readFile ../../hosts/silvermist/dns.json);
  nextcloudInstanceURL = "https://${silvermistDNS.subdomains.nextcloud}.${silvermistDNS.zone}";
  syncPathMap = {
    "/documents" = "${config.home.homeDirectory}/Documents";
    "/pictures" = "${config.home.homeDirectory}/Pictures";
    "/videos" = "${config.home.homeDirectory}/Videos";
    "/music" = "${config.home.homeDirectory}/Music";
  };
in
{
  sops.secrets."netrc".path = "${config.home.homeDirectory}/.netrc";
  systemd.user = {
    startServices = true;
    services.nextcloud-autosync = {
      Unit = {
        Description = "Auto sync Nextcloud";
        After = "network-online.target";
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.nextcloud-client}/bin/nextcloudcmd -h -n --path ${syncPathMap} ${nextcloudInstanceURL}";
        TimeoutStopSec = "3*60";
        KillMode = "process";
        KillSignal = "SIGINT";
      };
      Install.WantedBy = [ "multi-user.target" ];
    };
    timers.nextcloud-autosync = {
      Unit.Description = "Automatic sync files with Nextcloud when booted up after 1 minute then rerun every 15 minutes";
      Timer.OnBootSec = "1min";
      Timer.OnUnitActiveSec = "15min";
      Install.WantedBy = [
        "multi-user.target"
        "timers.target"
      ];
    };
  };
}
