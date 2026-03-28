{ config, ... }:
let
  wireguardPort = 62879;
  wireguardIF = "tunneltunnel";
  wgIp = "10.22.22";
  domusIp = "${wgIp}.22";
  domusPublicKey = "domucc9r8SkBuN3voZDs4KDj3TUQJiH08zQ2djO68g8=";
  haPort = 8123;
  printerPort = 80;
  printerWebcamPort = 9999;
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

  services.nginx.virtualHosts."${config.ldryt-infra.dns.records.domus}" = {
    enableACME = true;
    forceSSL = true;
    kTLS = true;
    locations."/" = {
      proxyPass = "http://${domusIp}:${toString haPort}";
      proxyWebsockets = true;
    };
  };

  services.nginx.virtualHosts."${config.ldryt-infra.dns.records.printer}" =
    let
      autheliaLocation = ./authelia/nginx-location.conf;
      autheliaRequest = ./authelia/nginx-authrequest.conf;
    in
    {
      enableACME = true;
      forceSSL = true;
      kTLS = true;
      extraConfig = "include ${autheliaLocation};";
      locations = {
        "/" = {
          proxyPass = "http://${domusIp}:${toString printerPort}";
          proxyWebsockets = true;
          extraConfig = ''
            include ${autheliaRequest};
            proxy_cache off;
            client_max_body_size 500M;
          '';
        };
        "/webcam" = {
          proxyPass = "http://${domusIp}:${toString printerWebcamPort}";
          extraConfig = ''
            include ${autheliaRequest};
            rewrite ^/webcam(/.*)?$ $1 break;
            postpone_output 0;
            proxy_buffering off;
            proxy_ignore_headers X-Accel-Buffering;
          '';
        };
      };
    };
}
