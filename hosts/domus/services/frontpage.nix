{
  config,
  pkgs,
  inputs,
  ...
}:
{
  services.nginx.virtualHosts."${config.ldryt-infra.dns.records.eu-web}" = {
    enableACME = true;
    forceSSL = true;
    root = "${
      (pkgs.callPackage ../../../pkgs/www.lucasladreyt.eu { theme = inputs.papermod; })
    }/public";
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
    locations."/".return = "301 https://${config.ldryt-infra.dns.records.eu-web}$request_uri";
    extraConfig = ''
      more_clear_headers "X-Robots-Tag";
    '';
  };

  services.nginx.virtualHosts."${config.ldryt-infra.dns.records.status}" = {
    enableACME = true;
    forceSSL = true;
    locations."/".return =
      "302 https://${config.ldryt-infra.dns.records.grafana}/public-dashboards/e5df93f80a7c456ea4c0a8828484bda8";
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
