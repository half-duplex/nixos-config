# Setup:
# https://github.com/nix-community/lanzaboote/blob/master/docs/QUICK_START.md
{
  config,
  lib,
  namespace,
  pkgs,
  ...
}: {
  options.${namespace}.boot.secureboot.enable = lib.mkOption {
    default = config.${namespace}.hardware == "physical";
    description = "Enable signing for Secure Boot";
    type = lib.types.bool;
  };

  config = lib.mkIf config.${namespace}.boot.secureboot.enable {
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
