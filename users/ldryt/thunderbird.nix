{ ... }:
{
  programs.thunderbird = {
    enable = true;
    settings = {
      "general.useragent.override" = "";
      "privacy.donottrackheader.enabled" = true;
      "mail.spellcheck.inline" = false;
    };
    profiles."main" = {
      isDefault = true;
    };
  };
}
