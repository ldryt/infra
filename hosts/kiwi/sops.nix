{ ... }: {
  sops.defaultSopsFile = ../../secrets/kiwi.yaml;
  sops.age.keyFile = "/var/lib/sops/sops_kiwi_age_key";

  sops.secrets."system/smb/glouton/credentials" = { };

  sops.secrets."users/colon/hashedPassword".neededForUsers = true;

  sops.secrets."services/authelia/jwtSecret" = { };
  sops.secrets."services/authelia/sessionSecret" = { };
  sops.secrets."services/authelia/storageEncryption" = { };
  sops.secrets."services/authelia/oidcHmacSecret" = { };
  sops.secrets."services/authelia/oidcIssuerPrivateKey" = { };
  sops.secrets."services/authelia/usersDB" = { };
  sops.secrets."services/authelia/postgresPassword" = { };

  sops.secrets."services/ocis/secret_envs" = { };
}
