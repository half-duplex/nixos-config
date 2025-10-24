{pkgs, ...}: {
  services = {
    displayManager.sddm.enable = true;
    libinput.enable = true;
    xserver.enable = true;
    desktopManager.plasma6.enable = true;
  };

  environment.systemPackages = with pkgs; [
    kdePackages.gwenview
  ];
}
