{ config, lib, ... }:
{
  sops.secrets."services/pi/mail/hashedPassword" = { };
  mailserver.accounts."pi@ldryt.dev" = {
    hashedPasswordFile = config.sops.secrets."services/pi/mail/hashedPassword".path;
    sendOnly = true;
  };

  services.postfix.settings.main = {
    smtpd_restriction_classes = [ "pi_local_recipients" ];
    pi_local_recipients = ''check_recipient_access pcre:{ {!/@ldryt\.dev\z/ REJECT Pi may only send to ldryt.dev recipients} }'';

    # Check the authenticated login before permitting relay.
    smtpd_relay_restrictions = lib.mkBefore [
      ''check_sasl_access pcre:{ {/^pi@ldryt\.dev\z/ pi_local_recipients} }''
    ];
  };
}
