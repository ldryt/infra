{
  config,
  pkgs-unstable,
  inputs,
  ...
}:
let
  dns = builtins.fromJSON (builtins.readFile ../dns.json);
  autheliaPublicFQDN = "${dns.subdomains.authelia}.${dns.zone}";
  autheliaInternalAddress = "localhost:44092";
in
{
  imports = [ "${inputs.nixpkgs-unstable}/nixos/modules/services/security/authelia.nix" ];
  disabledModules = [ "services/security/authelia.nix" ];

  sops.secrets."services/authelia/users".owner = config.services.authelia.instances.main.user;
  sops.secrets."services/authelia/jwtSecret".owner = config.services.authelia.instances.main.user;
  sops.secrets."services/authelia/storageEncryptionKey".owner =
    config.services.authelia.instances.main.user;
  sops.secrets."services/authelia/sessionSecret".owner = config.services.authelia.instances.main.user;
  sops.secrets."services/authelia/oidcHmacSecret".owner =  config.services.authelia.instances.main.user;
  sops.secrets."services/authelia/oidcIssuerPrivateKey".owner =  config.services.authelia.instances.main.user;

  services.authelia.instances.main = {
    enable = true;
    package = pkgs-unstable.authelia;

    secrets = {
      jwtSecretFile = config.sops.secrets."services/authelia/jwtSecret".path;
      storageEncryptionKeyFile = config.sops.secrets."services/authelia/storageEncryptionKey".path;
      sessionSecretFile = config.sops.secrets."services/authelia/sessionSecret".path;
      oidcHmacSecretFile = config.sops.secrets."services/authelia/oidcHmacSecret".path;
      oidcIssuerPrivateKeyFile = config.sops.secrets."services/authelia/oidcIssuerPrivateKey".path;
    };

    settings = {
      theme = "auto";

      log.format = "text";

      server.address = "tcp://${autheliaInternalAddress}/";

      storage.local.path = "/var/lib/authelia-${config.services.authelia.instances.main.name}/db.sqlite3";

      session.cookies = [
        {
          domain = autheliaPublicFQDN;
          authelia_url = "https://${autheliaPublicFQDN}";
        }
      ];

      access_control.default_policy = "two_factor";

      authentication_backend = {
        file.path = config.sops.secrets."services/authelia/users".path;
        password_reset.disable = true;
      };

      duo_api.disable = true;
      webauthn.disable = true;
      totp.issuer = autheliaPublicFQDN;

      notifier.smtp = {
        address = "smtp://localhost:25";
        sender = "auth@ldryt.dev";
        tls.server_name = "${dns.subdomains.postfix}.${dns.zone}";
      };
    };
  };

  services.nginx.virtualHosts."${dns.subdomains.authelia}.${dns.zone}" = {
    enableACME = true;
    forceSSL = true;
    kTLS = true;
    locations."/".proxyPass = "http://${autheliaInternalAddress}";
  };

  ldryt-infra.backups.authelia = {
    paths = [config.services.authelia.instances.main.settings.storage.local.path];
  };
}
