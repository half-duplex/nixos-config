{ pkgs, ... }:
{
    sconfig = {
        profile = "server";
        hardware = "qemu";
    };

    boot = {
        #initrd.kernelModules = [ "virtio_gpu" "drm" ];
        kernelParams = [ "console=ttyAMA0" ];
    };

    users.users.mal.openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEw0QgX7+nv9xsfHginV3pabQsoOIf96leLjglBfoQCk mal@awdbox.sec.gd"
    ];

    system.stateVersion = "21.05";
}
