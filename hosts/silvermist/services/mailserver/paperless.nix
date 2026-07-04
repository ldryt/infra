{ config, ... }:
{
  sops.secrets."services/paperless/mail/hashedPassword" = { };
  mailserver.accounts."paperless@ldryt.dev" = {
    hashedPasswordFile = config.sops.secrets."services/paperless/mail/hashedPassword".path;
    sendOnly = true;
  };
}
