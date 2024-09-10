{ config, pkgs, nixpkgs, ... }: {
  nixpkgs.overlays = [
    (_: _: { rutorrent = pkgs.nixpkgsUnstable.rutorrent; })
  ];
  services.rutorrent = {
    dataDir = "/persist/rutorrent";
    nginx.enable = true;
  };
}
