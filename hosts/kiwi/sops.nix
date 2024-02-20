{ config, ... }: {
  sops.defaultSopsFile = ../../secrets/kiwi.yaml;
  sops.age.keyFile = "/var/lib/sops/sops_kiwi_age_key";

  sops.secrets."system/smb/glouton/minio-buckets/credentials" = { };
  sops.secrets."system/smb/glouton/immich-library/credentials" = { };

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
  sops.secrets."services/authelia/smtpPassword".owner =
    config.services.authelia.instances.ldryt.user;

  sops.secrets."services/ocis/secretsConfig".owner =
    config.users.users.colon.name;
  sops.secrets."services/ocis/s3/credentials".owner =
    config.users.users.colon.name;

  sops.secrets."services/immich/credentials".owner =
    config.users.users.colon.name;

  sops.secrets."backups/restic/vaultwarden/repositoryPass".owner =
    config.users.users.vaultwarden.name;
  sops.secrets."backups/restic/vaultwarden/sshKey".owner =
    config.users.users.vaultwarden.name;
}
