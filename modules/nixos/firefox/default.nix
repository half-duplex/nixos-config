{
  config,
  pkgs,
  lib,
  namespace,
  ...
}: let
  ffLocked = value: {
    Status = "Locked";
    Value = value;
  };
in {
  options.${namespace}.programs.firefox.enable = lib.mkOption {
    default = config.${namespace}.archetypes.desktop.enable;
    description = "Install and configure Firefox";
    type = lib.types.bool;
  };

  config = lib.mkIf config.${namespace}.programs.firefox.enable {
    environment.variables.MOZ_USE_XINPUT2 = "1";
    programs.firefox = {
      enable = true;
      package = pkgs.nixpkgsUnstable.firefox;
      policies = {
        AutofillAddressEnabled = false;
        AutofillCreditCardEnabled = false;
        Cookies.Behavior = "reject-foreign";
        DisableFormHistory = true;
        DisablePocket = true;
        DisabledCiphers = {
          "TLS_RSA_WITH_AES_128_CBC_SHA" = true;
          "TLS_RSA_WITH_AES_256_CBC_SHA" = true;
          "TLS_RSA_WITH_3DES_EDE_CBC_SHA" = true;
        };
        DisplayBookmarksToolbar = "never";
        EnableTrackingProtection = {
          Value = true;
          Cryptomining = true;
          Fingerprinting = true;
          EmailTracking = true;
        };
        FirefoxHome = {
          Locked = true; # only locks params we set here
          Pocket = false;
          Search = false;
          SponsoredPocket = false;
          SponsoredTopSites = false;
        };
        FirefoxSuggest = {
          Locked = true;
          ImproveSuggest = false;
          SponsoredSuggestions = false;
          WebSuggestions = false;
        };
        HttpsOnlyMode = "force_enabled";
        NetworkPrediction = false;
        OfferToSaveLogins = false;
        PasswordManagerEnabled = false;
        Permissions = {
          Autoplay.Default = "block-audio-video";
          Notifications.BlockNewRequests = true;
        };
        PopupBlocking.Default = false;
        SanitizeOnShutdown.Cache = true; # History=true clears session
        SearchSuggestEnabled = false;
        SSLVersionMin = "tls1.2";
        ExtensionSettings = {
          "uBlock0@raymondhill.net" = {
            "installation_mode" = "normal_installed";
            "install_url" = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          };
        };
        Preferences = {
          "accessibility.blockautorefresh".Value = false;
          "browser.aboutConfig.showWarning" = ffLocked false;
          "browser.contentblocking.category".Value = "strict";
          "browser.discovery.enabled".Value = false;
          "browser.ml.chat.enabled".Value = false;
          "browser.ml.chat.sidebar".Value = false;
          "browser.newtabpage.enabled".Value = false;
          "browser.newtabpage.activity-stream.section.highlights.includeDownloads" = false;
          "browser.newtabpage.activity-stream.section.highlights.includeVisited" = false;
          "browser.newtabpage.activity-stream.showWeather" = ffLocked false; # not in FirefoxHome; fuck accuweather
          "browser.newtabpage.activity-stream.system.showSponsored" = ffLocked false; # ?
          "browser.sessionstore.warnOnQuit".Value = true;
          "browser.startup.page".Value = 3; # Restore session
          "browser.tabs.closeWindowWithLastTab".Value = false;
          "browser.tabs.tabMinWidth".Value = 70;
          "browser.uidensity".Value = 1;
          "browser.uitour.enabled".Value = false;
          "browser.urlbar.sponsoredTopSites" = ffLocked false;
          "browser.urlbar.suggest.quicksuggest.sponsored" = ffLocked false;
          "dom.disable_window_move_resize".Value = true;
          "dom.disable_window_flip".Value = true;
          "extensions.activeThemeID".Value = "firefox-compact-dark@mozilla.org";
          "extensions.formautofill.addresses.enabled" = ffLocked false;
          "extensions.formautofill.creditCards.enabled" = ffLocked false;
          "media.autoplay.blocking_policy".Value = 2; # 2=Click-to-play
          "network.dns.disablePrefetch".Value = true;
          "network.IDN_show_punycode".Value = true;
          "network.predictor.enabled".Value = false; # What *is* this??
          #"network.prefetch-next".Value = false;  # Benefit? Based on html tag
          "places.history.enabled".Value = false;
          "privacy.userContext.enabled".Value = true;
          "privacy.userContext.ui.enabled" = ffLocked true;
          "security.default_personal_cert".Value = "Ask Every Time";
          "security.insecure_connection_text.enabled".Value = true;
          "security.insecure_connection_text.pbmode.enabled".Value = true;
          "ui.prefersReducedMotion".Value = true;
        };
      };
      autoConfig = lib.concatStringsSep "\n" [
        # Prefs that can't be set by policy for "security/stability reasons"
        "defaultPref('privacy.firstparty.isolate', true)"
        "defaultPref('privacy.fingerprintingProtection', true)"
        "defaultPref('privacy.fingerprintingProtection.overrides', '+AllTargets,-CSSPrefersColorScheme')"
        # Maybe -JSDateTimeUTC too
        #"defaultPref('security.webauthn.ctap2', false)" # let me use u2f instead of passkeys
      ];
    };
  };
}
