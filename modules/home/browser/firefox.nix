{ inputs, ... }: {
  flake.modules.homeManager.firefox = { pkgs, ... }: {
    programs.firefox = {
      enable = true;
      policies = {
        DisableTelemetry = true;
        DisableFirefoxStudies = true;
        DisablePocket = true;
        DisableFirefoxAccounts = false;
        NoDefaultBookmarks = true;
        OfferToSaveLogins = false;
        OfferToSaveLoginsDefault = false;
        PasswordManagerEnabled = false;
        FirefoxHome = {
          Search = true;
          Pocket = false;
          Snippets = false;
          TopSites = false;
          Highlights = false;
        };
        UserMessaging = {
          ExtensionRecommendations = false;
          SkipOnboarding = true;
        };
      };
      profiles.default = {
        id = 0;
        name = "heph";
        isDefault = true;
        extensions.packages = with inputs.firefox-addons.packages.${pkgs.system}; [
          ublock-origin
          bitwarden
          user-agent-string-switcher
          multi-account-containers
          kagi-search
        ];
        settings = {
          "sidebar.verticalTabs" = true;
          "sidebar.revamp" = true;
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          "browser.newtabpage.activity-stream.showSponsored" = false;
          "browser.urlbar.suggest.quicksuggest.sponsored" = false;
          "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
          "browser.search.suggest.enabled" = false;
          "browser.search.suggest.enabled.private" = false;
          "browser.urlbar.suggest.searches" = false;
          "datareporting.healthreport.uploadEnabled" = false;
          "toolkit.telemetry.enabled" = false;
          "app.shield.optoutstudies.enabled" = false;
          "gfx.webrender.all" = true;
          "layers.acceleration.force-enabled" = true;
          "browser.tabs.drawInTitlebar" = true;
          "browser.shell.checkDefaultBrowser" = false;
          "general.smoothScroll" = true;
          "browser.sessionstore.resume_from_crash" = true;
          "browser.tabs.tabmanager.enabled" = false;
          "widget.use-xdg-desktop-portal.file-picker" = 1;
          "widget.use-xdg-desktop-portal.mime-handler" = 1;
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        };
      };
    };
  };
}
