{...}: {
  nixpkgs.overlays = [
    (
      _: prev: {
        telegram-desktop = prev.telegram-desktop.overrideAttrs (prevAttrs: {
          unwrapped = prevAttrs.unwrapped.overrideAttrs {
            patches =
              (prevAttrs.unwrapped.patches or [])
              ++ [
                patches/more-recent-stickers.patch
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
            separateDebugInfo = true;
          };
        });
      }
    )
  ];
}
