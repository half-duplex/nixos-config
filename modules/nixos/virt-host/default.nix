{
  config,
  lib,
  ...
}: let
  mvtip = config.multiverse.instance.at "tip";
in {
  virtualisation.libvirtd = {
    enable = true;
    hooks.daemon.powerpolicy-hook = ./libvirt-powerpolicy-hook.sh;
    package = mvtip.libvirt;
    parallelShutdown = 2;
    qemu = {
      runAsRoot = false;
      swtpm.enable = true;
    };
  };
  systemd.tmpfiles.settings = lib.mkIf config.virtualisation.libvirtd.enable {
    virtio-win."/var/lib/libvirt/images/virtio-win.iso"."L+".argument = "${mvtip.virtio-win.src}";
  };
}
