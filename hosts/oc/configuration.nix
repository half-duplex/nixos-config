{
  flake,
  hostName,
  lib,
  modulesPath,
  pkgs,
  ...
}: {
  imports = with flake.modules.nixos; [
    (modulesPath + "/profiles/qemu-guest.nix")
    base
    cli-minimal
  ];

  mal = {
    hardware = "qemu";
    secureBoot = false; # TODO
  };

  boot = {
    initrd.kernelModules = ["virtio_gpu" "drm"];
    #kernelParams = ["console=ttyAMA0"];
    kernelParams = ["console=ttyS0" "systemd.setenv=SYSTEMD_SULOGIN_FORCE=1"];
  };

  networking.hostName = hostName;

  users.users.mal.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEw0QgX7+nv9xsfHginV3pabQsoOIf96leLjglBfoQCk mal@awdbox"
  ];

  environment.systemPackages = with pkgs; [];

  #nixpkgs.hostPlatform = "aarch64-linux";
  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "25.11";
}
