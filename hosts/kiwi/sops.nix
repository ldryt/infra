{ ... }:
{
  sops.defaultSopsFile = ../../secrets/kiwi.yaml;
  sops.age.keyFile = "/var/lib/sops/age/main.key";

  sops.secrets."authelia/ldryt/jwtSecret" = {};
  sops.secrets."authelia/ldryt/sessionSecret" = {};
  sops.secrets."authelia/ldryt/storageEncryption" = {};
  sops.secrets."authelia/ldryt/oidcHmacSecret" = {};
  sops.secrets."authelia/ldryt/oidcIssuerPrivateKey" = {};
  sops.secrets."authelia/ldryt/usersDB" = {};
  sops.secrets."authelia/ldryt/postgresPassword" = {};
}
