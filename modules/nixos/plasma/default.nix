{
  config,
  pkgs,
  lib,
  namespace,
  ...
}: {
  options.${namespace}.desktop.plasma.enable = lib.mkEnableOption "Enable Plasma Desktop";

  config = lib.mkIf config.${namespace}.desktop.plasma.enable {
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
