# Setup: https://github.com/nix-community/lanzaboote/blob/master/docs/QUICK_START.md
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.mal.secureBoot;
in {
  options.mal.secureBoot = lib.mkOption {
    default = true;
    description = "Support Secure Boot";
    type = lib.types.bool;
  };

  imports = [inputs.lanzaboote.nixosModules.lanzaboote];
  config = mkIf cfg {
    boot = {
      loader.systemd-boot.enable = lib.mkForce false;
      lanzaboote = {
        enable = true;
        pkiBundle = "/etc/secureboot";
        settings.reboot-for-bitlocker = config.boot.loader.systemd-boot.rebootForBitlocker;
      };
    };
    environment.systemPackages = [pkgs.sbctl];
  };
}
