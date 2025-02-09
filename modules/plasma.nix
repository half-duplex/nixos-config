{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.sconfig.plasma;
in {
  options.sconfig.plasma = lib.mkEnableOption "Enable Plasma Desktop";

  config = lib.mkIf cfg {
    services = {
      displayManager.sddm.enable = true;
      libinput.enable = true;
      xserver = {
        enable = true;
        # Can't use wayland until it has global hotkeys
        #displayManager.defaultSession = "plasmawayland";
        desktopManager.plasma5.enable = true;
        desktopManager.plasma5.runUsingSystemd = true;
        desktopManager.plasma5.useQtScaling = true;
      };
    };

    environment.systemPackages = with pkgs; [
      libsForQt5.gwenview
      libsForQt5.bismuth
    ];
  };
}
