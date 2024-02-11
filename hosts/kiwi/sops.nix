{ ... }: {
  sops.defaultSopsFile = ../../secrets/kiwi.yaml;
  sops.age.keyFile = "/etc/ssh/ssh_host_ed25519_key";


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
