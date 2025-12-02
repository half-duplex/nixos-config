{
  config,
  lib,
  ...
}: let
  hardwareFor = name: cfg: lib.mkIf (config.mal.hardware == name) cfg;
in {
  options.mal.hardware = lib.mkOption {
    default = "physical";
    description = "A hardware preset for the host";
    type = lib.types.enum ["physical" "qemu" "rpi4"];
  };

  config = lib.mkMerge [
    (hardwareFor "physical" {
      services.fwupd.enable = true;
      virtualisation.libvirtd.enable = true;
    })
    (hardwareFor "qemu" {
      services.qemuGuest.enable = true;
    })
    (hardwareFor "rpi4" {
      mal.secureBoot = false;
      services.openssh.startWhenNeeded = true;
      #boot.kernelParams = ["console=ttyS1"];
    })
  ];
}
