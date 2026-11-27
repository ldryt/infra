{ config, ... }:
{
  sops.secrets."services/searx/secretKey" = { };
  sops.secrets."services/searx/htpasswd".owner = config.services.nginx.user;
  sops.templates."searxng.env".content = ''
    SEARXNG_SECRET_KEY=${config.sops.placeholder."services/searx/secretKey"}
  '';

  services.searx = {
    enable = true;
    configureUwsgi = true;
    uwsgiConfig = {
      http-socket = "127.0.0.1:8765";
      disable-logging = true;
    };
    environmentFile = config.sops.templates."searxng.env".path;
    settings = {
      use_default_settings.engines.remove = [ "google" ];
      server = {
        base_url = "https://${config.ldryt-infra.dns.records.searxng}/";
        secret_key = "$SEARXNG_SECRET_KEY";
      };
      search.formats = [
        "html"
        "json"
      ];
    };
  };

  services.nginx.virtualHosts.${config.ldryt-infra.dns.records.searxng} = {
    enableACME = true;
    forceSSL = true;
    basicAuthFile = config.sops.secrets."services/searx/htpasswd".path;
    extraConfig = "access_log off;";
    locations."/" = {
      proxyPass = "http://${config.services.searx.uwsgiConfig.http-socket}";
      extraConfig = ''
        proxy_set_header Authorization "";
      '';
    };
  };
}
