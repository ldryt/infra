{ config, pkgs, ... }:

{
  services.mysql.package = pkgs.mariadb;

  sops.secrets."services/firefox-syncserver/secrets" = { };
  services.firefox-syncserver = {
    enable = true;
    secrets = config.sops.secrets."services/firefox-syncserver/secrets".path;
    logLevel = "trace";
    singleNode = {
      enable = true;
      url = "https://${config.ldryt-infra.dns.records.firefox-syncserver}";
      capacity = 1;
    };
    settings.host = "0.0.0.0";
  };
  networking.firewall.allowedTCPPorts = [ config.services.firefox-syncserver.settings.port ];

  systemd.services.firefox-syncserver.serviceConfig.StateDirectory = "firefox-syncserver";
  environment.persistence.silvermist.directories = [
    "/var/lib/private/firefox-syncserver"
  ];
}
