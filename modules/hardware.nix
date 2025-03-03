{
  config,
  pkgs,
  lib,
  modulesPath,
  ...
}: let
  inherit (pkgs) callPackage;

  hardwareFor = name: cfg: lib.mkIf (config.sconfig.hardware == name) cfg;

  hardwareModules = [
    (hardwareFor "physical"
      {
        inherit (callPackage "${modulesPath}/installer/scan/not-detected.nix" {}) hardware;
        services.fwupd.enable = true;
        virtualisation.libvirtd.enable = true;
      })

    (hardwareFor "qemu"
      {
        inherit (callPackage "${modulesPath}/profiles/qemu-guest.nix" {config = config;}) boot;
        services.qemuGuest.enable = true;
      })

    (hardwareFor "rpi4"
      {
        inherit (callPackage "${modulesPath}/installer/scan/not-detected.nix" {}) hardware;
        boot.kernelParams = ["console=ttyS1"];
      })
  ];
in
  with lib; {
    options.sconfig.hardware = mkOption {
      type = types.enum ["physical" "qemu" "rpi4"];
    };

    config = mkMerge hardwareModules;
  }
