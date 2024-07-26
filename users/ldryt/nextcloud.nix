{ config, pkgs, ... }:
let
  silvermistDNS = builtins.fromJSON (builtins.readFile ../../hosts/silvermist/dns.json);
  nextcloudInstanceURL = "https://${silvermistDNS.subdomains.nextcloud}.${silvermistDNS.zone}";
  paths = [
    "/Documents"
    "/Music"
    "/Pictures"
    "/Videos"
  ];
  excludes = pkgs.writeText "nextcloudcmd-excludes" ''
    *.git
    .git
    .terraform
    *~
    ~$*
    .~lock.*
    ~*.tmp
    ]*.~*
    ]Icon\r*
    ].DS_Store
    ].ds_store
    ._*
    ]Thumbs.db
    System Volume Information
    .*.sw?
    .*.*sw?
    ].TemporaryItems
    ].Trashes
    ].DocumentRevisions-V100
    ].Trash-*
    .fseventd
    .apdisk
    .directory
    *.part
    *.filepart
    *.crdownload
    *.kate-swp
    *.gnucash.tmp-*
  '';
  syncCmd =
    path:
    "${pkgs.nextcloud-client}/bin/nextcloudcmd -n -h --exclude ${excludes} --path ${path} ${config.home.homeDirectory}${path} ${nextcloudInstanceURL}";
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
        ExecStart = pkgs.writeShellScript "nextcloudcmd-sync-script" ''
          ${builtins.concatStringsSep "\n" (map syncCmd paths)}
        '';
        TimeoutStopSec = "180";
        KillMode = "process";
        KillSignal = "SIGINT";
      };
      Install.WantedBy = [ "default.target" ];
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
