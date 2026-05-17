{ config, ... }:
let
  wg = {
    port = 62879;
    int = "wg-farmlab";
    ip = "10.22.22.1";
    farmlab = {
      ip = "10.22.22.22";
      pubKey = "/aWS4C9S3Yi8yVb74ROO2wZh/n5/mRAso9l3a/y5PVk=";
    };
  };
in
{
  ldryt-infra.monitoring.blackbox.targets = {
    http_protected = [
      "https://${config.ldryt-infra.dns.records.farmlab}/"
    ];
  };

  sops.secrets."services/farmlab-tunnel/privateKey".owner = "systemd-network";
  networking.firewall.allowedUDPPorts = [ wg.port ];
  systemd.network = {
    netdevs."10-${wg.int}" = {
      netdevConfig = {
        Kind = "wireguard";
        Name = wg.int;
      };
      wireguardConfig = {
        # KMj4U82/wzx0BpArJY5h1nQfm0PoVYLryhKdu5K6TAE=
        PrivateKeyFile = config.sops.secrets."services/farmlab-tunnel/privateKey".path;
        ListenPort = wg.port;
      };
      wireguardPeers = [
        {
          PublicKey = wg.farmlab.pubKey;
          AllowedIPs = [ "${wg.farmlab.ip}/32" ];
        }
      ];
    };
    networks."10-${wg.int}" = {
      matchConfig.Name = wg.int;
      address = [ "${wg.ip}/32" ];
    };
  };

  sops.secrets."services/farmlab-tunnel/oidc/clientSecret" = { };
  sops.secrets."services/farmlab-tunnel/oidc/cookieSecret" = { };
  services.oauth2-proxy = {
    enable = true;
    provider = "google";
    clientID = "757008932440-qvfa00r0cgtjvddnvrfe8raie9kap0fp.apps.googleusercontent.com";

    keyFile = config.sops.secrets."services/farmlab-tunnel/oidc/clientSecret".path;
    cookie.secret = config.sops.secrets."services/farmlab-tunnel/oidc/cookieSecret".path;

    email.domains = [
      "atelier-maker.fr"
    ];
  };

  services.nginx.virtualHosts."${config.ldryt-infra.dns.records.farmlab}" = {
    enableACME = true;
    forceSSL = true;
    locations = {
      "/oauth2/" = {
        proxyPass = config.services.oauth2-proxy.httpAddress;
        proxyWebsockets = true;
        extraConfig = ''
          proxy_set_header X-Auth-Request-Redirect $request_uri;
        '';
      };
      "/" = {
        proxyPass = "http://${wg.farmlab.ip}:80";
        proxyWebsockets = true;
        extraConfig = ''
          auth_request /oauth2/auth;
          error_page 401 = /oauth2/sign_in;

          proxy_cache off;
          client_max_body_size 500M;
        '';
      };
    };
  };
}
