{ config, ... }:
{
  sops.secrets."services/nix-cache/priv-key" = { };
  services.nix-serve = {
    enable = true;
    secretKeyFile = config.sops.secrets."services/nix-cache/priv-key".path;
  };
  services.nginx.virtualHosts."${config.ldryt-infra.dns.records.nix-cache}" = {
    forceSSL = true;
    enableACME = true;
    kTLS = true;
    locations."/".proxyPass =
      "http://${config.services.nix-serve.bindAddress}:${toString config.services.nix-serve.port}";
  };
}
