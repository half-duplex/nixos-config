{
  flake,
  hostName,
  nixos-raspberrypi,
  ...
}: {
  imports = with flake.modules.nixos; [
    nixos-raspberrypi.nixosModules.raspberry-pi-4.base
    base
    ./disks.nix
    cli-minimal

    samba
    #./backup-repo.nix
  ];

  mal = {
    hardware = "rpi4";
    secureBoot = false; # TODO
  };

  hardware.raspberry-pi.config.all = {
    options = {
      # TODO: kernel_watchdog_timeout?
      enable_uart = {
        enable = true;
        value = true;
      };
      uart_2ndstage = {
        enable = true;
        value = true;
      };
    };
  };

  boot.kernelParams = ["console=serial0,115200"];
  networking.hostName = hostName;

  users.users.mal.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILxOL5huR/1M3pIO0LlW4Z2zSKySUzp3dCqdN3e+TYTU mal@awdbox"
  ];

  nixpkgs.hostPlatform = "aarch64-linux";
  system.stateVersion = "25.05";
}
