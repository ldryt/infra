{ config, vars, ... }:
{
  sops.secrets."services/keycloak/db/password" = { };

  services.keycloak = {
    enable = true;
    initialAdminPassword = "matchbook-purse3";
    settings = {
      hostname = "${vars.services.keycloak.subdomain}.${vars.zone}";
      hostname-strict-backchannel = true;
      http-host = "127.0.0.1";
      http-port = 44085;
      proxy = "edge";
    };
    database = {
      createLocally = true;
      type = "mariadb";
      passwordFile = config.sops.secrets."services/keycloak/db/password".path;
    };
  };

  services.caddy.virtualHosts."${vars.services.keycloak.subdomain}.${vars.zone}".extraConfig = ''
    header {
      -Server
      Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
      X-Xss-Protection "1; mode=block"
      X-Content-Type-Options "nosniff"
      Permissions-Policy interest-cohort=()
      Content-Security-Policy "upgrade-insecure-requests"
      Referrer-Policy "strict-origin-when-cross-origin"
      Cache-Control "public, max-age=15, must-revalidate"
      Feature-Policy "accelerometer 'none'; ambient-light-sensor 'none'; autoplay 'self'; camera 'none'; encrypted-media 'none'; fullscreen 'self'; geolocation 'none'; gyroscope 'none';       magnetometer 'none'; microphone 'none'; midi 'none'; payment 'none'; picture-in-picture *; speaker 'none'; sync-xhr 'none'; usb 'none'; vr 'none'"
    }
    reverse_proxy http://${config.services.keycloak.settings.http-host}:${toString config.services.keycloak.settings.http-port}
  '';
}
