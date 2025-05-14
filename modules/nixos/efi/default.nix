{
  config,
  pkgs,
  lib,
  namespace,
  ...
}: {
  options.${namespace}.boot.mode = lib.mkOption {
    default = "efi";
    description = "Whether the system is booting in EFI or BIOS mode";
    type = lib.types.enum ["efi" "bios"];
  };

  config = lib.mkIf (config.${namespace}.boot == "efi") {
    boot = {
      # early module load may make boot.mount faster (boot critical-chain)
      initrd.kernelModules = ["vfat"];
      loader.efi.canTouchEfiVariables = true;
    };

    security.tpm2.enable = true;

    environment.systemPackages = with pkgs; [
      efibootmgr
    ];
  };
}
