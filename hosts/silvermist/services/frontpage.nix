{ config, pkgs, ... }:
{
  services.nginx.virtualHosts."${config.ldryt-infra.dns.records.eu-web}" = {
    enableACME = true;
    forceSSL = true;
    root = "${(pkgs.callPackage ../../../pkgs/www.lucasladreyt.eu { })}/public";
    extraConfig = ''
      more_clear_headers "X-Robots-Tag";
    '';
  };

  services.nginx.virtualHosts."${config.ldryt-infra.dns.records.ldryt-web}" = {
    enableACME = true;
    forceSSL = true;
    globalRedirect = config.ldryt-infra.dns.records.eu-web;
    extraConfig = ''
      more_clear_headers "X-Robots-Tag";
    '';
  };

  services.nginx.virtualHosts."${config.ldryt-infra.dns.zone}" = {
    enableACME = true;
    forceSSL = true;
    globalRedirect = config.ldryt-infra.dns.records.eu-web;
    extraConfig = ''
      more_clear_headers "X-Robots-Tag";
    '';
  };

  services.nginx.virtualHosts."lucasladreyt.eu" = {
    enableACME = true;
    forceSSL = true;
    globalRedirect = config.ldryt-infra.dns.records.eu-web;
    extraConfig = ''
      more_clear_headers "X-Robots-Tag";
    '';
  };
}
