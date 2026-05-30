{ inputs, ... }:

{
  imports = [ inputs.zen-browser.homeModules.default ];
  programs.zen-browser = {
    enable = true;
    setAsDefaultBrowser = true;
    policies = {
      DisableAppUpdate = true;
      DisableTelemetry = true;
      DisablePocket = true;
      DisableFeedbackCommands = true;
      DisableFirefoxStudies = true;
      DontCheckDefaultBrowser = true;
      NoDefaultBookmarks = true;
      OfferToSaveLogins = false;
      AutofillCreditCardEnabled = false;
      AutofillAddressEnabled = false;

      ExtensionSettings =
        let
          extension = shortId: {
            install_url = "https://addons.mozilla.org/en-US/firefox/downloads/latest/${shortId}/latest.xpi";
            installation_mode = "force_installed";
          };
        in
        {
          "uBlock0@raymondhill.net" = extension "ublock-origin";
          "idcac-pub@guus.ninja" = extension "istilldontcareaboutcookies";
          "sponsorBlocker@ajay.app" = extension "sponsorblock";
          "addon@darkreader.org" = extension "darkreader";
          "@testpilot-containers" = extension "multi-account-containers";
        };
    };

    profiles.default = {
      settings = {
        "dom.security.https_only_mode" = true;
        "media.ffmpeg.vaapi.enabled" = true;
        "gfx.webrender.all" = true;
        "browser.contentblocking.category" = "strict";
        "browser.search.suggest.enabled" = false;
        "browser.aboutwelcome.enabled" = false;
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "svg.context-properties.content.enabled" = true;

        "zen.window-sync.enabled" = false;
      };

      search = {
        force = true;
        default = "Kagi";
        engines = {
          "Kagi" = {
            urls = [ { template = "https://kagi.com/search?q={searchTerms}"; } ];
            definedAliases = [ "k" ];
          };
          "google" = {
            urls = [ { template = "https://www.google.com/search?q={searchTerms}"; } ];
            definedAliases = [ "g" ];
          };
          "Yandex" = {
            urls = [ { template = "https://yandex.com/search/?text={searchTerms}"; } ];
            definedAliases = [ "y" ];
          };
          "GitHub" = {
            urls = [ { template = "https://github.com/search?q={searchTerms}"; } ];
            definedAliases = [ "gh" ];
          };
          "MyNixOS" = {
            urls = [ { template = "https://mynixos.com/search?q={searchTerms}"; } ];
            definedAliases = [ "nx" ];
          };
        };
      };
    };
  };
}
