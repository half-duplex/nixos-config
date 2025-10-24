{
  config,
  lib,
  options,
  ...
}: let
  inherit (lib) hasAttr mkIf;
  zram = config.zramSwap.enable;
in {
  config =
    lib.attrsets.recursiveUpdate {
      zramSwap.enable = lib.mkDefault true;

      boot.kernel.sysctl = mkIf zram {
        # https://cmm.github.io/soapbox/the-year-of-linux-on-the-desktop.html
        "vm.swappiness" = 180;
        "vm.page-cluster" = 0;
        "vm.watermark_scale_factor" = 125;
        "vm.watermark_boost_factor" = 0;
      };

      # enable zswap on 25.05 (no boot.kernel.sysfs)
      boot.kernelParams = mkIf (!zram && !hasAttr "sysfs" options.boot.kernel) [
        "zswap.enabled=1"
        "zswap.shrinker_enabled=1"
      ];
    } (lib.optionalAttrs (hasAttr "sysfs" options.boot.kernel) {
      boot.kernel.sysfs.module.zswap.parameters = lib.mkIf (!zram) {
        enabled = true;
        shrinker_enabled = true;
      };
    });
}
