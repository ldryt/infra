{ config, pkgs-unstable, inputs, ... }:
let
  dns = builtins.fromJSON (builtins.readFile ../dns.json);
in
{
  imports = [
    "${inputs.nixpkgs-unstable}/nixos/modules/services/security/authelia.nix"
  ];
  disabledModules = [
    "services/security/authelia.nix"
  ];

  sops.secrets."services/authelia/users".owner = config.services.authelia.instances.main.user;
  sops.secrets."services/authelia/smtpPassword".owner = config.services.authelia.instances.main.user;
  sops.secrets."services/authelia/jwtSecret".owner = config.services.authelia.instances.main.user;
  sops.secrets."services/authelia/storageEncryptionKey".owner =
    config.services.authelia.instances.main.user;
  sops.secrets."services/authelia/sessionSecret".owner = config.services.authelia.instances.main.user;

  services.authelia.instances.main = {
    enable = true;
    package = pkgs-unstable.authelia;

    environmentVariables = {
      AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE = config.sops.secrets."services/authelia/smtpPassword".path;
    };
    secrets = {
      jwtSecretFile = config.sops.secrets."services/authelia/jwtSecret".path;
      storageEncryptionKeyFile = config.sops.secrets."services/authelia/storageEncryptionKey".path;
      sessionSecretFile = config.sops.secrets."services/authelia/sessionSecret".path;
    };

    settings = {
      theme = "auto";

      log = {
        format = "text";
        level = "trace";
      };

      server.address = "tcp://localhost:44092/";

      storage.local.path = "/var/lib/authelia/db.sqlite3";

      authentication_backend = {
        file.path = config.sops.secrets."services/authelia/users".path;
        password_reset.disable = true;
      };

      duo_api.disable = true;
      webauthn.disable = true;
      totp.issuer = "${dns.subdomains.authelia}.${dns.zone}";

      notifier.smtp = {
        address = "smtp://in-v3.mailjet.com:587";
        username = "773c12eb23aff9be95348dc406c73d9d";
        sender = "auth@ldryt.dev";
      };
    };
  };
}
