{
  config,
  lib,
  pkgs,
  ...
}: let
  mvtip = config.multiverse.instance.at "tip";
in {
  systemd.tmpfiles.settings = lib.mkIf config.virtualisation.libvirtd.enable {
    virtio-win."/var/lib/libvirt/images/virtio-win.iso".L.argument = "${mvtip.virtio-win.src}";
  };
}
