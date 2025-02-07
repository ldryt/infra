{ pkgs, config, ... }:
let
  dns = builtins.fromJSON (builtins.readFile ../dns.json);
  wireguardPort = 62879;
  wireguardIF = "tunneltunnel";
  wgIp = "10.22.22";
  domusIp = "${wgIp}.22";
  domusPort = 8123;
  domusPublicKey = "domucc9r8SkBuN3voZDs4KDj3TUQJiH08zQ2djO68g8=";
  printerIp = "${wgIp}.122";
  printerPort = "80";
  printerPublicKey = "prINTGfGjKLhBAByRVQwE4hA/yWq9waKh3NrjzqsyDo=";
in
{
  sops.secrets."system/networking/wireguard/privateKey".owner = "systemd-network";
  networking.firewall.allowedUDPPorts = [ wireguardPort ];
  systemd.network = {
    netdevs."10-${wireguardIF}" = {
      netdevConfig = {
        Kind = "wireguard";
        Name = wireguardIF;
      };
      wireguardConfig = {
        PrivateKeyFile = config.sops.secrets."system/networking/wireguard/privateKey".path;
        ListenPort = wireguardPort;
      };
      wireguardPeers = [
        {
          # domus
          PublicKey = domusPublicKey;
          AllowedIPs = [ domusIp ];
        }
        {
          # printer
          PublicKey = printerPublicKey;
          AllowedIPs = [ printerIp ];
        }
      ];
    };
    networks."10-${wireguardIF}" = {
      matchConfig.Name = wireguardIF;
      address = [ "${wgIp}.1/24" ];
      networkConfig = {
        IPMasquerade = "ipv4";
        IPv4Forwarding = true;
      };
    };
  };

  services.nginx.virtualHosts."${dns.subdomains.domus}.${dns.zone}" = {
    enableACME = true;
    forceSSL = true;
    kTLS = true;
    locations."/" = {
      proxyPass = "http://${domusIp}:${toString domusPort}";
      proxyWebsockets = true;
    };
  };

  services.nginx.virtualHosts."${dns.subdomains.printer}.${dns.zone}" = let 
      autheliaLocation = pkgs.writeText "authelia-location.conf" ''
        ## Virtual endpoint created by nginx to forward auth requests.
        location /internal/authelia/authz {
          ## Essential Proxy Configuration
          internal;
          proxy_pass http://127.0.0.1:44092/api/authz/auth-request;

          ## Headers
          ## The headers starting with X-* are required.
          proxy_set_header X-Original-Method $request_method;
          proxy_set_header X-Original-URL $scheme://$http_host$request_uri;
          proxy_set_header X-Forwarded-For $remote_addr;
          proxy_set_header Content-Length "";
          proxy_set_header Connection "";

          ## Basic Proxy Configuration
          proxy_pass_request_body off;
          proxy_next_upstream error timeout invalid_header http_500 http_502 http_503; # Timeout if the real server is dead
          proxy_redirect http:// $scheme://;
          proxy_http_version 1.1;
          proxy_cache_bypass $cookie_session;
          proxy_no_cache $cookie_session;
          proxy_buffers 4 32k;
          client_body_buffer_size 128k;

          ## Advanced Proxy Configuration
          send_timeout 5m;
          proxy_read_timeout 240;
          proxy_send_timeout 240;
          proxy_connect_timeout 240;
        }
      '';
      autheliaRequest = pkgs.writeText "authelia-authrequest.conf" ''
        auth_request /internal/authelia/authz;

        ## Save the upstream metadata response headers from Authelia to variables.
        auth_request_set $user $upstream_http_remote_user;
        auth_request_set $groups $upstream_http_remote_groups;
        auth_request_set $name $upstream_http_remote_name;
        auth_request_set $email $upstream_http_remote_email;

        ## Inject the metadata response headers from the variables into the request made to the backend.
        proxy_set_header Remote-User $user;
        proxy_set_header Remote-Groups $groups;
        proxy_set_header Remote-Email $email;
        proxy_set_header Remote-Name $name;

        ## Set the $redirection_url to the Location header of the response to the Authz endpoint.
        auth_request_set $redirection_url $upstream_http_location;
        ## When there is a 401 response code from the authz endpoint redirect to the $redirection_url.
        error_page 401 =302 $redirection_url;
      '';
  in
  {
    enableACME = true;
    forceSSL = true;
    kTLS = true;
    extraConfig = "include ${autheliaLocation};";
    locations."/" = {
        proxyPass = "http://${printerIp}:${toString printerPort}";
        proxyWebsockets = true;
        extraConfig = "include ${autheliaRequest};";
    };
  };
}
