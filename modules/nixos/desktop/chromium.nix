{
  config,
  pkgs,
  lib,
  ...
}: let
  extraRecommended = config.programs.chromium.extraOptsRecommended;
in {
  options.programs.chromium.extraOptsRecommended = lib.mkOption {
    type = lib.types.attrs;
    description = ''
      Like extraOpts, but "recommended" instead of "mandatory".
    '';
    default = {};
  };

  config = {
    environment.systemPackages = with pkgs; [chromium];
    programs.chromium = {
      enable = true;
      extensions = [
        "cjpalhdlnbpafiamejdnhcphjbkeiagm" # uBlock Origin
        "ddkjiahejlhfcafbddmgiahcphecmpfh" # uBlock Origin Lite
      ];
      # Mandatory
      extraOpts = {
        AdsSettingForIntrusiveAdsSites = 2; # block
        AutofillAddressEnabled = false;
        AutofillCreditCardEnabled = false;
        BackgroundModeEnabled = false;
        DefaultBrowserSettingEnabled = false;
        DefaultNotificationsSetting = 2; # block
        DefaultPopupsSetting = 2; # block
        ExtensionManifestV2Availability = 2;
        HttpsOnlyMode = "force_enabled";
        MetricsReportingEnabled = false;
        NetworkPredictionOptions = 2; # none
        PasswordManagerEnabled = false;
        PrivacySandboxAdMeasurementEnabled = false;
        PrivacySandboxAdTopicsEnabled = false;
        PrivacySandboxPromptEnabled = false;
        PrivacySandboxSiteEnabledAdsEnabled = false;
        SearchSuggestEnabled = false;
        SpellCheckServiceEnabled = false;
        SyncDisabled = true;
        UrlKeyedAnonymizedDataCollectionEnabled = false;

        # GenAI
        GenAiDefaultSettings = 2; # block. ignored
        CreateThemesSettings = 2; # block
        DevToolsGenAiSettings = 2; # block
        HelpMeWriteSettings = 2; # block. unclear if cloud or local
        HistorySearchSettings = 2; # block. unclear if cloud or local
        TabCompareSettings = 2; # block. unclear if cloud or local
      };
      extraOptsRecommended = {
        AutoplayAllowed = false;
        BlockThirdPartyCookies = true;
        BrowserSignin = 0;
        SafeBrowsingProtectionLevel = 1;
      };
    };
    environment.etc = {
      "chromium/policies/recommended/extra.json" = lib.mkIf (extraRecommended != {}) {
        text = builtins.toJSON extraRecommended;
      };
      "opt/chrome/policies/recommended/extra.json" = lib.mkIf (extraRecommended != {}) {
        text = builtins.toJSON extraRecommended;
      };
    };
  };
}
