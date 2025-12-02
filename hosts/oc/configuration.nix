{
  flake,
  hostName,
  modulesPath,
  pkgs,
  ...
}: {
  imports = with flake.modules.nixos; [
    (modulesPath + "/profiles/qemu-guest.nix")
    base
    cli
  ];

  mal = {
    hardware = "qemu";
  };

  # Delay for network device - work around https://github.com/NixOS/nixpkgs/issues/98741
  #boot.initrd.preLVMCommands = lib.mkOrder 400 "sleep 2";

  boot = {
    #initrd.kernelModules = [ "virtio_gpu" "drm" ];
    kernelParams = ["console=ttyAMA0"];
  };

  networking.hostName = hostName;

  users.users.mal.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEw0QgX7+nv9xsfHginV3pabQsoOIf96leLjglBfoQCk mal@awdbox"
  ];

  environment.systemPackages = with pkgs; [];

  nixpkgs.hostPlatform = "aarch64-linux";
  system.stateVersion = "25.05";
}
