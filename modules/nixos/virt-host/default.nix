{
  config,
  lib,
  ...
}: let
  mvtip = config.multiverse.instance.at "tip";
in {
  #config = lib.mkIf config.virtualisation.libvirtd.enable {
  virtualisation.libvirtd = {
    enable = true;
    package = mvtip.libvirt;
    hooks.daemon.powerpolicy-hook = ./libvirt-powerpolicy-hook.sh;
  };
  systemd.tmpfiles.settings = lib.mkIf config.virtualisation.libvirtd.enable {
    virtio-win."/var/lib/libvirt/images/virtio-win.iso"."L+".argument = "${mvtip.virtio-win.src}";
  };
  #};
}
