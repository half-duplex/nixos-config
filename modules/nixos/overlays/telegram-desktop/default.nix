{pkgs, ...}: let
  inherit (pkgs) fetchFromGitHub;
in {
  nixpkgs.overlays = [
    (
      _: prev: {
        telegram-desktop = prev.telegram-desktop.overrideAttrs (finalAttrs: prevAttrs: {
          unwrapped = prevAttrs.unwrapped.overrideAttrs {
            version = "7.0.5";
            src = fetchFromGitHub {
              owner = "telegramdesktop";
              repo = "tdesktop";
              rev = "v${finalAttrs.version}";
              fetchSubmodules = true;
              hash = "sha256-uWV5pvQHUrJpWsS+biYtMPvi2B5dxi7F9mCV4JYyz+Q=";
            };

            nativeBuildInputs =
              (prevAttrs.unwrapped.nativeBuildInputs or [])
              ++ [
                pkgs.qt6.qtshadertools
              ];
            buildInputs =
              (prevAttrs.unwrapped.buildInputs or [])
              ++ [
                pkgs.minizip
                pkgs.cmark-gfm
              ];

            patches =
              (prevAttrs.unwrapped.patches or [])
              ++ [
                patches/disable-gift-buttons.patch
                # Based on https://github.com/Layerex/telegram-desktop-patches/tree/master
                patches/disable-sponsored-messages.patch
                patches/disable-save-restrictions.patch
                (prev.pkgs.fetchpatch {
                  url = "https://github.com/Layerex/telegram-desktop-patches/raw/36e27074851c64e52706adc606d1a9bfc12a3194/0003-Disable-invite-peeking-restrictions.patch";
                  hash = "sha256-8mJD6LOjz11yfAdY4QPK/AUz9o5W3XdupXxy7kRrbC8=";
                })
                (prev.pkgs.fetchpatch {
                  url = "https://github.com/Layerex/telegram-desktop-patches/raw/36e27074851c64e52706adc606d1a9bfc12a3194/0004-Disable-accounts-limit.patch";
                  hash = "sha256-PZWCFdGE/TTJ1auG1JXNpnTUko2rCWla6dYKaQNzreg=";
                })
              ];
          };
        });
      }
    )
  ];
}
