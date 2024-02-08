{ ... }: {
  sops.defaultSopsFile = ../../secrets/encrypted.yaml;
  sops.age.keyFile = "/var/lib/sops/age/main.key";


  sops.secrets."users/ldryt/hashedPassword".neededForUsers = true;
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
