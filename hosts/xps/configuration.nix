{ pkgs, ... }:
{
    sconfig = {
        dvorak = true;
        plasma = true;
        profile = "desktop";
        hardware = "physical";
        #security-tools = true;
    };

    boot.initrd.availableKernelModules = [ "nvme" ];

    users.users.mal.openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKYenMcXumgnwcAVa40KGhyXX3/VPqIZ9/YIej3g+RMC mal@luca.sec.gd"
    ];

    hardware.video.hidpi.enable = true;
    services.xserver.dpi = 192; # needed until >21.05
    system.stateVersion = "21.05";
}
