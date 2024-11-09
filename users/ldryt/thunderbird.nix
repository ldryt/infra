{ ... }:
{
  home.file."thunderbird-gnome-theme" = {
    target = ".thunderbird/main/chrome/thunderbird-gnome-theme";
    source = (
      fetchTarball {
        url = "https://github.com/rafaelmardojai/thunderbird-gnome-theme/archive/628fcccb7788e3e0ad34f67114f563c87ac8c1dc.tar.gz";
        sha256 = "0ypf3z17brvbkx6vhy31l786ap753r3ly1ffcc3jpn3xbj7bsx84";
      }
    );
  };

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
      userChrome = ''
        @import "thunderbird-gnome-theme/userChrome.css";
      '';
      userContent = ''
        @import "thunderbird-gnome-theme/userContent.css";
      '';
    };
  };
}
