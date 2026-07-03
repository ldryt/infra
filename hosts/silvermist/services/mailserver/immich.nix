{ config, ... }:
{
  sops.secrets."services/immich/mail/hashedPassword" = { };
  mailserver.accounts."pics@ldryt.dev" = {
    hashedPasswordFile = config.sops.secrets."services/immich/mail/hashedPassword".path;
    sendOnly = true;
  };
}
