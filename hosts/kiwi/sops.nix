{ config, ... }: {
  sops.defaultSopsFile = ../../secrets/kiwi.yaml;
  sops.age.keyFile = "/var/lib/sops/sops_kiwi_age_key";

  sops.secrets."system/smb/glouton/credentials" = { };

  sops.secrets."users/colon/hashedPassword".neededForUsers = true;

  sops.secrets."services/authelia/jwtSecret".owner =
    config.services.authelia.instances.ldryt.user;
  sops.secrets."services/authelia/sessionSecret".owner =
    config.services.authelia.instances.ldryt.user;
  sops.secrets."services/authelia/storageEncryption".owner =
    config.services.authelia.instances.ldryt.user;
  sops.secrets."services/authelia/oidcHmacSecret".owner =
    config.services.authelia.instances.ldryt.user;
  sops.secrets."services/authelia/oidcIssuerPrivateKey".owner =
    config.services.authelia.instances.ldryt.user;
  sops.secrets."services/authelia/usersDB".owner =
    config.services.authelia.instances.ldryt.user;
  sops.secrets."services/authelia/postgresPassword" = {
    # owner = config.services.authelia.instances.ldryt.user;
    # group = "postgres";
    mode = "0444"; # "0440";
  };

  sops.secrets."services/ocis/secretsConfig".owner =
    config.users.users.colon.name;
}
