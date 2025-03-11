{ firefox-addons, ... }:
{
  home.file."firefox-gnome-theme" = {
    target = ".mozilla/firefox/default/chrome/firefox-gnome-theme";
    source = (
      fetchTarball {
        url = "https://github.com/rafaelmardojai/firefox-gnome-theme/archive/refs/tags/v135.tar.gz";
        sha256 = "02b5d05z9p3la4rm39570wd3l0f87gicnkiylx1blp05bf27vl9s";
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
      ];
      search = {
        default = "Google";
        force = true;
        engines = {
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
          "Perplexity" = {
            urls = [ { template = "https://www.perplexity.ai/?q={searchTerms}"; } ];
            iconUpdateURL = "https://www.perplexity.ai/favicon.ico";
            updateInterval = 7 * 24 * 60 * 60 * 1000;
            definedAliases = [ "p" ];
          };
          "Phind" = {
            urls = [ { template = "https://www.phind.com/search?q={searchTerms}&ignoreSearchResults=false"; } ];
            iconUpdateURL = "https://www.phind.com/images/favicon.png";
            updateInterval = 7 * 24 * 60 * 60 * 1000;
            definedAliases = [ "ph" ];
          };
        };
      };
      settings = {
        # Telemetry settings
        # Disable various telemetry and data reporting settings to enhance privacy
        "devtools.onboarding.telemetry.logged" = false; # Disables telemetry for DevTools onboarding
        "app.shield.optoutstudies.enabled" = false; # Disables Shield studies (experimental features sent via telemetry)
        "browser.newtabpage.activity-stream.feeds.telemetry" = false; # Disables telemetry on Firefox's new tab page
        "browser.newtabpage.activity-stream.telemetry" = false; # Disables additional telemetry on the new tab page
        "browser.ping-centre.telemetry" = false; # Disables Ping Centre telemetry
        "toolkit.telemetry.bhrPing.enabled" = false; # Disables background hang reports
        "toolkit.telemetry.enabled" = false; # Disables all telemetry
        "toolkit.telemetry.firstShutdownPing.enabled" = false; # Disables telemetry ping on the first shutdown
        "toolkit.telemetry.hybridContent.enabled" = false; # Disables telemetry for hybrid content
        "toolkit.telemetry.newProfilePing.enabled" = false; # Disables telemetry ping when a new profile is created
        "toolkit.telemetry.reportingpolicy.firstRun" = false; # Disables telemetry reporting on the first run
        "toolkit.telemetry.shutdownPingSender.enabled" = false; # Disables shutdown telemetry ping
        "toolkit.telemetry.unified" = false; # Disables unified telemetry
        "toolkit.telemetry.updatePing.enabled" = false; # Disables update telemetry ping
        "toolkit.telemetry.archive.enabled" = false; # Disables telemetry archiving
        "datareporting.healthreport.uploadEnabled" = false; # Disables health report upload
        "datareporting.policy.dataSubmissionEnabled" = false; # Disables data submission for reports
        "datareporting.sessions.current.clean" = true; # Cleans up session data

        # Security settings
        "dom.security.https_only_mode" = true; # Enforces HTTPS-only mode for all connections
        "dom.security.https_only_mode_ever_enabled" = true; # Tracks if HTTPS-only mode was ever enabled

        # Privacy settings
        "browser.search.suggest.enabled" = false; # Disables search suggestions
        "extensions.formautofill.creditCards.enabled" = false; # Disables autofill for credit card data
        "signon.autofillForms" = false; # Disables automatic form autofill
        "browser.formfill.enable" = false; # Disables saving and filling forms
        "signon.rememberSignons" = false; # Disables saving login credentials
        "privacy.trackingprotection.emailtracking.enabled" = true; # Enables email tracking protection
        "privacy.trackingprotection.enabled" = true; # Enables tracking protection
        "privacy.trackingprotection.socialtracking.enabled" = true; # Enables social tracking protection
        "privacy.resistFingerprinting.randomization.enabled" = true; # Randomizes fingerprinting for increased privacy
        "browser.contentblocking.category" = "strict"; # Sets content blocking to strict mode

        # Miscellaneous settings
        "browser.aboutwelcome.enabled" = false; # Disables the welcome screen on first run
        "app.update.auto" = false; # Disables automatic updates
        "identity.fxaccounts.enabled" = false; # Disables Firefox account integration
        "extensions.pocket.enabled" = false; # Disables Pocket integration
        "gfx.webrender.all" = true; # Enables WebRender for improved graphics performance
        "media.ffmpeg.vaapi.enabled" = true; # Enables VA-API (hardware acceleration for video on Linux)
        "reader.parse-on-load.force-enabled" = true; # Enables Reader Mode on all pages
        "privacy.webrtc.legacyGlobalIndicator" = false; # Disables legacy global indicator for WebRTC
        "browser.newtabpage.activity-stream.showSponsored" = false; # Disables sponsored content on new tab page
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false; # Disables sponsored top sites
        "browser.newtabpage.activity-stream.feeds.snippets" = false; # Disables snippets on new tab page
        "browser.toolbars.bookmarks.visibility" = "never"; # Hides bookmarks toolbar
        "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" = false; # Disables add-on recommendations
        "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" = false; # Disables feature recommendations
        "extensions.htmlaboutaddons.recommendations.enabled" = false; # Disables add-on recommendations in Add-ons Manager
        "layout.spellcheckDefault" = 0; # Disables spellcheck

        # Firefox-GNOME Theme settings
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true; # Enables custom stylesheets for user themes
        "svg.context-properties.content.enabled" = true; # Allows SVG filters for custom themes
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
