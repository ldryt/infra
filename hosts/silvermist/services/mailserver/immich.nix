{ config, ... }:
{
  sops.secrets."services/immich/mail/hashedPassword" = { };
  mailserver.loginAccounts."pics@ldryt.dev" = {
    hashedPasswordFile = config.sops.secrets."services/immich/mail/hashedPassword".path;
    sendOnly = true;
  };
}
