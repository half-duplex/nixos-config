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
  options.${namespace}.archetypes.desktop = {
    enable = lib.mkOption {
      default = false;
      description = "Install a desktop environment and related tools and config";
      type = lib.types.bool;
    };
  };

  config = lib.mkIf config.${namespace}.archetypes.desktop.enable {
    time.timeZone = "US/Eastern";

    hardware.bluetooth.enable = true;
    networking.networkmanager.enable = true;

    services.xserver.xkb.options = "compose:ralt";

    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };

    environment.variables.MOZ_USE_XINPUT2 = "1";

    environment.systemPackages = with pkgs; [
      ddcui
      ddcutil
      gparted
      ntfs3g
      pavucontrol
      powertop
      redshift

      carla
      rnnoise-plugin
      ffmpeg-full
      mediainfo
      gimp
      exiftool
      yt-dlp

      wine
      dxvk

      discord
      element-desktop
      evolution
      #nixpkgsUnstable.obsidian  # Requires ancient electron
      signal-desktop
      teamspeak_client
      telegram-desktop
      thunderbird

      alacritty
      chirp
      gedit
      gnome-text-editor
      ghidra
      imhex
      #pgadmin # ancient
      (nixpkgsUnstable.proxmark3.override {hardwarePlatform = "PM3GENERIC";})
      remmina
      virt-manager
      wireshark

      chromium
      evince # may be implicit with gnome
      google-chrome
      libreoffice-fresh
      nixpkgsStaging.tor-browser
      yubikey-manager
      yubikey-manager-qt
      zoom-us

      protontricks
      r2modman

      android-tools

      (mpv.override {scripts = [mpvScripts.mpris];})

      (vscode-with-extensions.override {
        vscodeExtensions = with pkgs.vscode-extensions; [
          #ms-python.python  # https://github.com/NixOS/nixpkgs/issues/262000
          ms-vscode.cpptools
        ];
      })

      (wrapFirefox nixpkgsStaging.firefox-unwrapped {
        extraPolicies = {
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
            WebSuggest = false;
            ImproveSuggest = false;
            SponsoredSuggestions = false;
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
            "browser.newtabpage.enabled".Value = false;
            "browser.newtabpage.activity-stream.section.highlights.includeDownloads" = false;
            "browser.newtabpage.activity-stream.section.highlights.includeVisited" = false;
            "browser.newtabpage.activity-stream.showWeather" = ffLocked false; # not in FirefoxHome; fuck accuweather
            "browser.newtabpage.activity-stream.system.showSponsored" = ffLocked false; # ?
            "browser.sessionstore.warnOnQuit".Value = true;
            "browser.startup.page".Value = 3; # Restore session
            "browser.tabs.closeWindowWithLastTab".Value = false;
            "browser.tabs.tabMinWidth".Value = 70;
            "browser.urlbar.sponsoredTopSites" = ffLocked false;
            "browser.urlbar.suggest.quicksuggest.sponsored" = ffLocked false;
            "browser.uidensity".Value = 1;
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
            # Can't be set by policy for "security/stability reasons"
            #"privacy.firstparty.isolate".Value = true;
            #"privacy.resistFingerprinting".Value = true;
            #"privacy.fingerprintingProtection".Value = true;
            # Maybe -JSDateTimeUTC too
            #"privacy.fingerprintingProtection.overrides".Value = "+AllTargets,-CSSPrefersColorScheme";
            #"security.webauth.u2f".Value = false;  # I want webauthn
          };
        };
      })
    ];

    #programs.adb.enable = true;
    services.flatpak.enable = true;
    services.udev.packages = [pkgs.android-udev-rules];
    services.pcscd.enable = true; # yubikey ccid/piv
    users.users.mal.extraGroups = ["adbusers"];
    security = {
      polkit.enable = true;
      pam.services.kwallet.enableKwallet = true;
    };
    programs = {
      _1password.enable = true;
      _1password-gui = {
        enable = true;
        polkitPolicyOwners = ["mal"];
      };
      dconf.enable = true;
      steam.enable = true;
    };
    nixpkgs.overlays = [
      (final: prev: {
        steam = prev.steam.override ({extraLibraries ? pkgs': [], ...}: {
          extraLibraries = pkgs':
            (extraLibraries pkgs')
            ++ [
              pkgs'.gperftools
            ];
        });
      })
    ];
  };
}
