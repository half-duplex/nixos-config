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
      # Can't use wayland until it has global hotkeys
      xserver.enable = true;
      #displayManager.defaultSession = "plasmax11";
      desktopManager.plasma6.enable = true;
    };

    environment.systemPackages = with pkgs; [
      kdePackages.gwenview
    ];
  };
}
