{ config, pkgs, lib, ... }:
with lib;
{
    config = mkIf (config.sconfig.profile == "desktop") {
        sconfig.alacritty.enable = true;

        networking.networkmanager.enable = true;

        services.xserver.xkbOptions = "compose:ralt";
        services.pipewire = {
            enable = true;
            pulse.enable = true;
            alsa.enable = true;
            alsa.support32Bit = true;
        };

        environment.systemPackages = with pkgs; [
            carla
            discord
            ffmpeg
            gimp
            pavucontrol
            powertop
            qemu_kvm
            redshift
            tdesktop
            teamspeak_client
            wine
            youtube-dl

            (mpv-with-scripts.override { scripts = [ mpvScripts.mpris ]; })

            (vscode-with-extensions.override {
                vscodeExtensions = with pkgs.vscode-extensions; [
                    ms-python.python
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
                        "network.cookie.cookieBehavior" = { Status = "locked"; Value = 5; };
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
                        "security.webauth.u2f" = { Status = "locked"; Value = false; }; # I want fido
                        "ui.prefersReducedMotion" = { Status = "locked"; Value = 1; };
                    };
                };
            })
        ];

        programs.steam.enable = true;
    };
}