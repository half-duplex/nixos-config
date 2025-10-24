{pkgs, ...}: {
  boot = {
    # early module load may make boot.mount faster (boot critical-chain)
    initrd.kernelModules = ["vfat"];
    loader.efi.canTouchEfiVariables = true;
  };

  security.tpm2.enable = true;

  environment.systemPackages = with pkgs; [
    efibootmgr
  ];
}
