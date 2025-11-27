{
  config,
  flake,
  hostName,
  lib,
  ...
}: {
  imports = with flake.modules.nixos; [
    base
    desktop
    plasma
  ];

  mal = {
    hardware = "physical";
    remoteUnlock.enable = false;
  };

  boot.initrd.kernelModules = ["nvme"];
  boot.initrd.availableKernelModules = ["amdgpu"];
  hardware.cpu.amd.updateMicrocode = true;

  users.users.mal.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIt2xxDXFBkIOODdasb1v0253kZqUa8UydrLCOtffQot mal@awdbox"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE7zzehsT3U/TAe2LYhpuVmuJzkcp6ZeDiCW3lY7FNWv mal@awen"
  ];

  networking.hostName = hostName;

  fileSystems =
    lib.foldl (a: b: a // b)
    {
      "/mnt/awdbox/data" = {
        device = "awdbox:/data";
        fsType = "nfs";
        options = ["noauto" "nfsvers=4" "sec=krb5p"];
      };
    }
    (lib.forEach (lib.range 1 5) (n: {
      "/mnt/crypt${toString n}" = {
        device = "/dev/mapper/crypt${toString n}";
        options = ["noauto" "noatime"];
      };
    }));

  services = {
    avahi.enable = true;
    openssh.startWhenNeeded = true;
    openvpn.servers.commercial = {
      config = "config ${config.sops.secrets."openvpn_t14s_commercial".path}";
    };
    tor = {
      enable = true;
      client.enable = true;
    };
    zfs.autoScrub.enable = false; # battery
  };

  sops.secrets."openvpn_t14s_commercial".sopsFile = secrets/openvpn.yaml;

  systemd.services.libvirtd.wantedBy = lib.mkForce [];
  systemd.services.libvirt-guests.wantedBy = lib.mkForce [];
  virtualisation.libvirtd.onBoot = "ignore"; # doesn't disable libvirt-guests.service
  systemd.services.openvpn-commercial.wantedBy = lib.mkForce [];
  systemd.services.tor.wantedBy = lib.mkForce [];

  programs.gnupg.agent.enable = true;

  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "25.05";
}
