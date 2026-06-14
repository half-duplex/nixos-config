{
  config,
  lib,
  ...
}: {
  # Use zswap if there's disk-backed swap, else zram

  boot.zswap = lib.mkIf (builtins.length config.swapDevices > 0) {
    enable = true;
    #maxPoolPercent = 30;
  };

  zramSwap.enable = lib.mkDefault (!config.boot.zswap.enable);
  boot.kernel.sysctl = lib.mkIf config.zramSwap.enable {
    # https://cmm.github.io/soapbox/the-year-of-linux-on-the-desktop.html
    "vm.swappiness" = 180;
    "vm.page-cluster" = 0;
    "vm.watermark_scale_factor" = 125;
    "vm.watermark_boost_factor" = 0;
  };
}
