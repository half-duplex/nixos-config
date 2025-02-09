{
  config,
  pkgs,
  lib,
  lanzaboote,
  ...
}: let
  cfg = config.sconfig.secureboot;
in {
  options.sconfig.secureboot = lib.mkEnableOption "Enable SecureBoot";

  config = lib.mkIf cfg {
    boot = {
      loader.systemd-boot.enable = lib.mkForce false;
      lanzaboote = {
        enable = true;
        pkiBundle = "/etc/secureboot";
      };
    };
    environment.systemPackages = [pkgs.sbctl];
  };
}
