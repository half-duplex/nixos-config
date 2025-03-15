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
    boot.loader.efi.canTouchEfiVariables = true;

    security.tpm2.enable = true;

    environment.systemPackages = with pkgs; [
      efibootmgr
    ];
  };
}
