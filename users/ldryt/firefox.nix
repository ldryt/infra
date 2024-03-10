{ ... }: {
  home.file."firefox-gnome-theme" = {
    target = ".mozilla/firefox/default/chrome/firefox-gnome-theme";
    source = (fetchTarball {
      url =
        "https://github.com/rafaelmardojai/firefox-gnome-theme/archive/refs/tags/v122.tar.gz";
      sha256 = "0mack8i6splsywc5h0bdgh1njs4rm8fsi0lpvvwmbdqmjjlkz6a1";
    });
  };

  programs.firefox = {
    enable = true;
    profiles.default = {
      #    extensions = with nur.repos.rycee.firefox-addons; [
      #      ublock-origin
      #      bitwarden
      #      darkreader
      #    ];
      search = {
        default = "Google";
        force = true;
        engines = {
          "Bing".metaData.hidden = true;
          "Amazon.fr".metaData.hidden = true;
          "Wikipedia (en)".metaData.hidden = true;
        };
      };
      settings = {
        "app.update.auto" = false;
        "identity.fxaccounts.enabled" = false;
        "extensions.pocket.enabled" = false;
        "gfx.webrender.all" = true;
        "media.ffmpeg.vaapi.enabled" = true;
        "reader.parse-on-load.force-enabled" = true;
        "privacy.webrtc.legacyGlobalIndicator" = false;
        "app.shield.optoutstudies.enabled" = false;
        "dom.security.https_only_mode" = true;
        "browser.newtabpage.activity-stream.showSponsored" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        "browser.newtabpage.activity-stream.feeds.snippets" = false;
        "browser.contentblocking.category" = "strict";
        "browser.toolbars.bookmarks.visibility" = "never";
        "browser.formfill.enable" = false;
        "signon.autofillForms" = false;
        "signon.rememberSignons" = false;
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "svg.context-properties.content.enabled" = true;
        # "gnomeTheme.hideSingleTab" = true;
        # "gnomeTheme.bookmarksToolbarUnderTabs" = true;
        # "gnomeTheme.normalWidthTabs" = false;
        # "gnomeTheme.tabsAsHeaderbar" = false;
      };
      userChrome = ''
        @import "firefox-gnome-theme/userChrome.css";
      '';
      userContent = ''
        @import "firefox-gnome-theme/userContent.css";
      '';
    };
  };
}
