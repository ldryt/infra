{ config, ... }:
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
      settings = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "svg.context-properties.content.enabled" = true;
      };
    };
  };

  xdg.configFile."autostart/thunderbird.desktop".source =
    "${config.programs.thunderbird.package}/share/applications/thunderbird.desktop";
}
