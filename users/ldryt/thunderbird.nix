{ ... }: {
  home.file."thunderbird-gnome-theme" = {
    target = ".thunderbird/main/chrome/thunderbird-gnome-theme";
    source = (fetchTarball {
      url =
        "https://github.com/rafaelmardojai/thunderbird-gnome-theme/archive/966e9dd54bd2ce9d36d51cd6af8c3bac7a764a68.tar.gz";
      sha256 = "0msyi9aar6f2ciw8w8bymvx03zfdx67qasac2v0i1sc9py3sivib";
    });
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
