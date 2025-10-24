{
  config,
  pkgs,
  lib,
  modulesPath,
  ...
}: let
  inherit (pkgs) callPackage;
  hardwareFor = name: cfg: lib.mkIf (config.mal.hardware == name) cfg;
in {
  options.mal.hardware = lib.mkOption {
    default = "physical";
    description = "A hardware preset for the host";
    type = lib.types.enum ["physical" "qemu" "rpi4"];
  };

  config = lib.mkMerge [
    (hardwareFor "physical" {
      inherit (callPackage "${modulesPath}/installer/scan/not-detected.nix" {}) hardware;
      services.fwupd.enable = true;
      virtualisation.libvirtd.enable = true;
    })
    (hardwareFor "qemu" {
      inherit (callPackage "${modulesPath}/profiles/qemu-guest.nix" {config = config;}) boot;
      services.qemuGuest.enable = true;
    })
    (hardwareFor "rpi4" {
      inherit (callPackage "${modulesPath}/installer/scan/not-detected.nix" {}) hardware;
      mal.secureBoot = false;
      services.openssh.startWhenNeeded = true;
      #boot.kernelParams = ["console=ttyS1"];
    })
  ];
}
