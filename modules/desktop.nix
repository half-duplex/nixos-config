{ config, pkgs, lib, ... }:
with lib;
{
  config = mkIf (config.sconfig.profile == "desktop") {
    time.timeZone = "US/Eastern";

    sconfig.alacritty.enable = true;

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

    environment.systemPackages = with pkgs; [
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
      yt-dlp

      wine
      dxvk

      discord
      element-desktop
      evolution
      #nixpkgsUnstable.obsidian  # Requires ancient electron
      signal-desktop
      teamspeak_client
      (telegram-desktop.overrideAttrs (prevAttrs: {
        unwrapped = prevAttrs.unwrapped.overrideAttrs {
          patches = ( prevAttrs.unwrapped.patches or [] ) ++ [
            ../patches/telegram-desktop_more-recent-stickers.patch
            # Based on https://github.com/Layerex/telegram-desktop-patches/tree/master
            ../patches/telegram-desktop_disable-sponsored-messages.patch
            ../patches/telegram-desktop_disable-save-restrictions.patch
            (fetchpatch {
              url = "https://github.com/Layerex/telegram-desktop-patches/raw/b7a73c0b8a8b3527f69959ce3ceb35f8dbde8a8e/0003-Disable-invite-peeking-restrictions.patch";
              hash = "sha256-8mJD6LOjz11yfAdY4QPK/AUz9o5W3XdupXxy7kRrbC8=";
            })
            (fetchpatch {
              url = "https://github.com/Layerex/telegram-desktop-patches/raw/b7a73c0b8a8b3527f69959ce3ceb35f8dbde8a8e/0004-Disable-accounts-limit.patch";
              hash = "sha256-PZWCFdGE/TTJ1auG1JXNpnTUko2rCWla6dYKaQNzreg=";
            })
          ];
        };
      }))
      thunderbird

      chirp
      gedit
      gnome-text-editor
      ghidra
      #pgadmin # ancient
      (nixpkgsUnstable.proxmark3.override { hardwarePlatform = "PM3GENERIC"; })
      remmina
      virt-manager
      wireshark

      chromium
      evince  # may be implicit with gnome
      google-chrome
      libreoffice-fresh
      nixpkgsStaging.tor-browser
      yubikey-manager
      yubikey-manager-qt
      zoom-us

      protontricks
      r2modman

      android-tools

      (mpv.override { scripts = [ mpvScripts.mpris ]; })

      (vscode-with-extensions.override {
        vscodeExtensions = with pkgs.vscode-extensions; [
          #ms-python.python  # https://github.com/NixOS/nixpkgs/issues/262000
          ms-vscode.cpptools
        ];
      })

      (wrapFirefox nixpkgsStaging.firefox-unwrapped {
        extraPolicies = {
          DisablePocket = true;
          OfferToSaveLogins = false;
          DisableFormHistory = true;
          SearchSuggestEnabled = false;
          Preferences = {
            "accessibility.blockautorefresh" = { Status = "locked"; Value = false; };
            "browser.aboutConfig.showWarning" = { Status = "locked"; Value = false; };
            "browser.contentblocking.category" = { Status = "locked"; Value = "strict"; };
            "browser.discovery.enabled" = { Status = "locked"; Value = false; };
            "browser.newtabpage.enabled" = { Status = "locked"; Value = false; };
            "browser.search.suggest.enabled" = { Status = "locked"; Value = false; };
            "browser.sessionstore.warnOnQuit" = { Status = "locked"; Value = true; };
            "browser.startup.page" = { Status = "locked"; Value = 3; };
            "browser.tabs.closeWindowWithLastTab" = { Status = "locked"; Value = false; };
            "browser.tabs.tabMinWidth" = { Status = "locked"; Value = 66; };
            "browser.toolbars.bookmarks.visibility" = { Status = "locked"; Value = "never"; };
            "browser.uidensity" = { Status = "locked"; Value = 1; };
            "dom.security.https_only_mode" = { Status = "locked"; Value = true; };
            "media.autoplay.default" = { Status = "locked"; Value = 5; };
            "media.autoplay.blocking_policy" = { Status = "locked"; Value = 2; };
            "network.IDN_show_punycode" = { Status = "locked"; Value = true; };
            # network.dns.disablePrefetch
            # network.http.speculative-parallel-limit
            # network.predictor.enabled
            # network.prefetch-next
            # places.history.enabled = false
            "privacy.firstparty.isolate" = { Status = "locked"; Value = true; };
            "privacy.resistFingerprinting" = { Status = "locked"; Value = true; };
            "privacy.userContext.enabled" = { Status = "locked"; Value = true; };
            #"privacy.userContext.longPressBehavior" = { Status = "locked"; Value = 2; }; # removed?
            "privacy.userContext.ui.enabled" = { Status = "locked"; Value = true; };
            "security.ssl3.rsa_aes_128_sha" = { Status = "locked"; Value = false; };
            "security.ssl3.rsa_aes_256_sha" = { Status = "locked"; Value = false; };
            "security.ssl3.rsa_des_ede3_sha" = { Status = "locked"; Value = false; };
            "security.webauth.u2f" = { Status = "locked"; Value = false; }; # I want webauthn
            "ui.prefersReducedMotion" = { Status = "locked"; Value = 1; };
          };
        };
      })
    ];

    #programs.adb.enable = true;
    services.flatpak.enable = true;
    services.udev.packages = [ pkgs.android-udev-rules ];
    services.pcscd.enable = true;  # yubikey ccid/piv
    users.users.mal.extraGroups = [ "adbusers" ];
    security = {
      polkit.enable = true;
      pam.services.kwallet.enableKwallet = true;
    };
    programs = {
      _1password.enable = true;
      _1password-gui = {
        enable = true;
        polkitPolicyOwners = [ "mal" ];
      };
      dconf.enable = true;
      steam.enable = true;
    };
    nixpkgs.overlays = [
      (final: prev: {
        steam = prev.steam.override ({ extraLibraries ? pkgs': [], ... }: {
          extraLibraries = pkgs': (extraLibraries pkgs') ++ ( [
            pkgs'.gperftools
          ]);
        });
      })
    ];
  };
}
