{ config, pkgs, lib, modulesPath, ... }:
let

  inherit (pkgs) callPackage;

  hardwareFor = name: cfg: lib.mkIf (config.sconfig.hardware == name) cfg;

  hardwareModules =
    [
      (hardwareFor "physical"
        {
          inherit (callPackage "${modulesPath}/installer/scan/not-detected.nix" { }) hardware;
          services.fwupd.enable = true;
          environment.systemPackages = with pkgs; [
            qemu_kvm
            libvirt
          ];
        })

      (hardwareFor "qemu"
        {
          inherit (callPackage "${modulesPath}/profiles/qemu-guest.nix" { }) boot;
          services.qemuGuest.enable = true;
        })
    ];

in
with lib;
{
  options.sconfig.hardware = mkOption {
    type = types.enum [ "physical" "qemu" ];
  };

  config = mkMerge hardwareModules;
}
