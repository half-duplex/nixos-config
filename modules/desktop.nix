{ config, pkgs, lib, ... }:
with lib;
{
  config = mkIf (config.sconfig.profile == "desktop") {
    sconfig.alacritty.enable = true;

    hardware.bluetooth.enable = true;
    networking.networkmanager.enable = true;

    services.xserver.xkbOptions = "compose:ralt";
    services.pipewire = {
      enable = true;
      pulse.enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
    };

    environment.systemPackages = with pkgs; [
      tor-browser-bundle-bin
      gparted
      ntfs3g
      pavucontrol
      powertop
      redshift

      carla
      ffmpeg-full
      gimp
      youtube-dl

      wine
      dxvk

      discord
      #unstable.obsidian  # Requires ancient electron
      signal-desktop
      tdesktop
      teamspeak_client
      thunderbird

      chirp
      gedit
      gnome-text-editor
      ghidra
      #pgadmin # ancient
      remmina
      virt-manager
      wireshark

      chromium
      google-chrome
      libreoffice-fresh
      yubikey-manager
      yubikey-manager-qt
      zoom

      unstable.r2modman

      unstable.android-tools

      (mpv.override { scripts = [ mpvScripts.mpris ]; })

      (vscode-with-extensions.override {
        vscodeExtensions = with pkgs.vscode-extensions; [
          #ms-python.python  # https://github.com/NixOS/nixpkgs/issues/262000
          ms-vscode.cpptools
        ];
      })

      (wrapFirefox firefox-unwrapped {
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
  };
}
