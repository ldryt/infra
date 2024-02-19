{ config, ... }:
let
  hidden = import ../../../secrets/obfuscated.nix;
  vaultwardenSubdomain = "pass";
in {
  services.vaultwarden = {
    enable = true;
    config = {
      DOMAIN = "https://${vaultwardenSubdomain}.${hidden.ldryt.host}";
      SIGNUPS_ALLOWED = "true";
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 44083;
    };
  };

  services.nginx = {
    virtualHosts."${vaultwardenSubdomain}.${hidden.ldryt.host}" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        recommendedProxySettings = true;
        proxyPass =
          "http://${config.services.vaultwarden.config.ROCKET_ADDRESS}:${
            toString config.services.vaultwarden.config.ROCKET_PORT
          }";
      };
    };
  };
}
