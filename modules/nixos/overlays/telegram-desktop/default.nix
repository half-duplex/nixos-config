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
                # https://github.com/NixOS/nixpkgs/issues/497549
                (prev.pkgs.fetchpatch {
                  url = "https://gist.github.com/half-duplex/d95e4fda535fb72ad0246ccfbe55cb23/raw/410dc924a317d391226c338ab75fcd1a9aaaf91b/tdesktop-minizip-include.patch";
                  hash = "sha256-lvEE5ZGmOjulZCg/rgrvAOTjUpJsAOcga+sAzr8FtYA=";
                })
              ];
          };
        });
      }
    )
  ];
}
