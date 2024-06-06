{ ... }:
{
  home.file."thunderbird-gnome-theme" = {
    target = ".thunderbird/main/chrome/thunderbird-gnome-theme";
    source = (
      fetchTarball {
        url = "https://github.com/rafaelmardojai/thunderbird-gnome-theme/archive/65d5c03fc9172d549a3ea72fd366d544981a002b.tar.gz";
        sha256 = "1l295w61h5469328qkjggny3mjq1x0q3zr9p8pz5sq5pypc7604x";
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
