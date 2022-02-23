{ config, pkgs, lib, ... }:
let
  cfg = config.sconfig.alacritty;
in
{
  options.sconfig.alacritty.enable = lib.mkEnableOption "Enable Alacritty";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.alacritty ];
  };
}
