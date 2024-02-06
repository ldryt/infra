{ ... }: {
  programs.firefox.enable = true;
  programs.firefox = {
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
      };
    };
  };
}
