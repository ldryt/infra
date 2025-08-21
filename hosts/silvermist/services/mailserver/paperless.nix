{ config, ... }:
{
  sops.secrets."services/paperless/mail/hashedPassword" = { };
  mailserver.loginAccounts."paperless@ldryt.dev" = {
    hashedPasswordFile = config.sops.secrets."services/paperless/mail/hashedPassword".path;
    sendOnly = true;
  };
}
