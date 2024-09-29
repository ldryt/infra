{ firefox-addons, ... }:
{
  home.file."firefox-gnome-theme" = {
    target = ".mozilla/firefox/default/chrome/firefox-gnome-theme";
    source = (
      fetchTarball {
        url = "https://github.com/rafaelmardojai/firefox-gnome-theme/archive/refs/tags/v129.tar.gz";
        sha256 = "14x0vp66i8b14q6c9n75sa88fcwy9jd9lik8sjnab2rnwlskvq9h";
      }
    );
  };

  programs.firefox = {
    enable = true;
    profiles.default = {
      extensions = with firefox-addons.packages."x86_64-linux"; [
        bitwarden
        ublock-origin
        sponsorblock
        youtube-shorts-block
      ];
      search = {
        default = "Google";
        force = true;
        engines = {
          "Phind" = {
            urls = [ { template = "https://www.phind.com/search?q={searchTerms}&ignoreSearchResults=false"; } ];
            iconUpdateURL = "https://www.phind.com/images/favicon.png";
            updateInterval = 7 * 24 * 60 * 60 * 1000;
            definedAliases = [ "p" ];
          };
          "GitHub" = {
            urls = [ { template = "https://github.com/search?q={searchTerms}"; } ];
            iconUpdateURL = "https://github.com/fluidicon.png";
            updateInterval = 7 * 24 * 60 * 60 * 1000;
            definedAliases = [ "gh" ];
          };
          "WolframAlpha" = {
            urls = [ { template = "https://www.wolframalpha.com/input?i={searchTerms}"; } ];
            iconUpdateURL = "https://www.wolframalpha.com/_next/static/images/favicon_1zbE9hjk.ico";
            updateInterval = 7 * 24 * 60 * 60 * 1000;
            definedAliases = [ "wa" ];
          };
          "MyNixOS" = {
            urls = [ { template = "https://mynixos.com/search?q={searchTerms}"; } ];
            iconUpdateURL = "https://mynixos.com/favicon-dark.svg";
            updateInterval = 7 * 24 * 60 * 60 * 1000;
            definedAliases = [ "nx" ];
          };
          "Noogle" = {
            urls = [ { template = "https://noogle.dev/q?term={searchTerms}"; } ];
            iconUpdateURL = "https://noogle.dev/favicon.png";
            updateInterval = 7 * 24 * 60 * 60 * 1000;
            definedAliases = [ "no" ];
          };
        };
      };
      settings = {
        # telemetry
        # https://support.mozilla.org/en-US/questions/1197144#question-reply
        # https://www.howtogeek.com/557929/how-to-see-and-disable-the-telemetry-data-firefox-collects-about-you/
        "devtools.onboarding.telemetry.logged" = false;
        "app.shield.optoutstudies.enabled" = false;
        "browser.newtabpage.activity-stream.feeds.telemetry" = false;
        "browser.newtabpage.activity-stream.telemetry" = false;
        "browser.ping-centre.telemetry" = false;
        "toolkit.telemetry.bhrPing.enabled" = false;
        "toolkit.telemetry.enabled" = false;
        "toolkit.telemetry.firstShutdownPing.enabled" = false;
        "toolkit.telemetry.hybridContent.enabled" = false;
        "toolkit.telemetry.newProfilePing.enabled" = false;
        "toolkit.telemetry.reportingpolicy.firstRun" = false;
        "toolkit.telemetry.shutdownPingSender.enabled" = false;
        "toolkit.telemetry.unified" = false;
        "toolkit.telemetry.updatePing.enabled" = false;
        "toolkit.telemetry.archive.enabled" = false;
        "datareporting.healthreport.uploadEnabled" = false;
        "datareporting.policy.dataSubmissionEnabled" = false;
        "datareporting.sessions.current.clean" = true;

        # security
        "dom.security.https_only_mode" = true;
        "dom.security.https_only_mode_ever_enabled" = true;

        # privacy
        "browser.search.suggest.enabled" = false;
        "extensions.formautofill.creditCards.enabled" = false;
        "signon.autofillForms" = false;
        "browser.formfill.enable" = false;
        "signon.rememberSignons" = false;
        "privacy.trackingprotection.emailtracking.enabled" = true;
        "privacy.trackingprotection.enabled" = true;
        "privacy.trackingprotection.socialtracking.enabled" = true;
        "privacy.resistFingerprinting.randomization.enabled" = true;
        "browser.contentblocking.category" = "strict";

        # misc
        "browser.aboutwelcome.enabled" = false;
        "app.update.auto" = false;
        "identity.fxaccounts.enabled" = false;
        "extensions.pocket.enabled" = false;
        "gfx.webrender.all" = true;
        "media.ffmpeg.vaapi.enabled" = true;
        "reader.parse-on-load.force-enabled" = true;
        "privacy.webrtc.legacyGlobalIndicator" = false;
        "browser.newtabpage.activity-stream.showSponsored" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        "browser.newtabpage.activity-stream.feeds.snippets" = false;
        "browser.toolbars.bookmarks.visibility" = "never";
        "browser.download.useDownloadDir" = false; # Ask where to save downloads
        "browser.translations.enable" = false; # disable translations
        "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" = false; # Do not recommend addons
        "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" = false; # Do not recommend features
        "extensions.htmlaboutaddons.recommendations.enabled" = false; # Do not recommend extensions
        "layout.spellcheckDefault" = 0; # Spellcheck off

        # firefox-gnome-theme
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "svg.context-properties.content.enabled" = true;
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
