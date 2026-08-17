{
  config,
  flake,
  hostName,
  lib,
  modulesPath,
  pkgs,
  ...
}: {
  imports = with flake.modules.nixos; [
    (modulesPath + "/installer/scan/not-detected.nix")
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
  boot.extraModprobeConfig = ''
    options zfs zfs_arc_sys_free=${toString (2 * 1024 * 1024 * 1024)}
  '';
  hardware.cpu.amd.updateMicrocode = true;

  users.users.mal.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIt2xxDXFBkIOODdasb1v0253kZqUa8UydrLCOtffQot mal@awdbox"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE7zzehsT3U/TAe2LYhpuVmuJzkcp6ZeDiCW3lY7FNWv mal@awen"
  ];

  networking.hostName = hostName;
  networking.networkmanager.dispatcherScripts = [
    {
      source = pkgs.writeText "captive-portal-clicker" ''
        set -x
        action="$2"
        if [ "$action" == "up" ] ; then
          logger "checking captive portals for $2"
          ssid=$(${pkgs.networkmanager}/bin/nmcli -g 802-11-wireless.ssid conn show "$CONNECTION_UUID")
          if [ "$ssid" == "Amtrak_WiFi" ] ; then
            timeout 1 ${pkgs.curl}/bin/curl http://8.8.8.8/ --head -s \
              | grep -qi '^Location: https://amtrak.on.icomera.com/cna/' \
              && ${pkgs.curl}/bin/curl -s 'https://www.ombord.info/hotspot/hotspot.cgi?method=login&url=https://www.amtrak.com/wifi/amtrakwifi.html&onerror=https://amtrak.on.icomera.com/'
            logger "done captive portal"
          fi
        fi
      '';
      type = "basic";
    }
  ];

  swapDevices = [
    {
      device = "/dev/disk/by-partuuid/14c47044-9e43-4494-942d-9a4dae20a24c";
      options = ["nofail"];
      randomEncryption = {
        enable = true;
        allowDiscards = true;
        sectorSize = 4096;
      };
    }
  ];
  fileSystems =
    lib.foldl (a: b: a // b)
    {
      "/mnt/awdbox/data" = {
        device = "awdbox:/mnt/data";
        fsType = "nfs";
        options = ["noauto" "nfsvers=4" "sec=krb5p"];
      };
    }
    (lib.forEach (lib.range 1 5) (n: {
      "/mnt/crypt${toString n}" = {
        device = "/dev/mapper/crypt${toString n}";
        fsType = "auto";
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
