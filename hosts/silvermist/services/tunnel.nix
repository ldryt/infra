{ config, ... }:
let
  wireguardPort = 62879;
  wireguardIF = "printertunnel";
  wgIp = "10.22.22";
  printerIp = "${wgIp}.22";
  printerPublicKey = "domucc9r8SkBuN3voZDs4KDj3TUQJiH08zQ2djO68g8=";
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
          proxyPass = "http://${printerIp}:${toString printerPort}";
          proxyWebsockets = true;
          extraConfig = ''
            include ${autheliaRequest};
            proxy_cache off;
            client_max_body_size 500M;
          '';
        };
        "/webcam" = {
          proxyPass = "http://${printerIp}:${toString printerWebcamPort}/";
          proxyWebsockets = true;
          extraConfig = ''
            include ${autheliaRequest};
            postpone_output 0;
            proxy_buffering off;
            proxy_ignore_headers X-Accel-Buffering;
          '';
        };
      };
    };
}
