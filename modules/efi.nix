{ config, pkgs, lib, ... }:
{
  options.sconfig.boot = lib.mkOption {
    type = lib.types.enum [ "efi" "bios" ];
    default = "efi";
  };

  config = lib.mkIf (config.sconfig.boot == "efi") {
    boot.loader.efi.canTouchEfiVariables = true;

    security.tpm2.enable = true;

    environment.systemPackages = with pkgs; [
      efibootmgr
    ];
  };
}
