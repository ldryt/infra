{ config, ... }:
{
  sops.secrets."services/grafana/mail/hashedPassword" = { };
  mailserver.accounts."graph@ldryt.dev" = {
    hashedPasswordFile = config.sops.secrets."services/grafana/mail/hashedPassword".path;
    sendOnly = true;
  };
}
