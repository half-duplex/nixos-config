{ config, pkgs, nixpkgs, ... }: {
  nixpkgs.overlays = [
    (_: _: { rutorrent = pkgs.nixpkgsUnstable.rutorrent; })
  ];
  environment.systemPackages = with pkgs; [
    pyrosimple
    transmission  # useful for transmission-show etc
  ];
  services.rutorrent = {
    dataDir = "/persist/rutorrent";
    plugins = [
      "httprpc"
      "_getdir"
      "_noty2"
      "_task"
      "autotools"
      "chunks"
      "data"
      "datadir"
      "diskspace"
      "edit"
      "erasedata"
      "filedrop"
      "geoip"
      "history"
      "mediainfo"
      "seedingtime"
      "theme"
      "throttle"
      "tracklabels"
    ];
    nginx.enable = true;
  };
}
