{
  flake,
  hostName,
  modulesPath,
  nixos-raspberrypi,
  ...
}: {
  imports = with flake.modules.nixos; [
    (modulesPath + "/installer/scan/not-detected.nix")
    nixos-raspberrypi.nixosModules.raspberry-pi-4.base
    nixos-raspberrypi.nixosModules.raspberry-pi-4.display-vc4
    base
    cli-minimal

    samba
    #./backup-repo.nix
  ];
  # fix output dying in stage1 when vc4 fails to load a fw blob or something
  # https://github.com/nvmd/nixos-raspberrypi/issues/49
  boot.blacklistedKernelModules = ["vc4"];

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

  boot.kernelParams = [
    "ip=10.0.0.9::10.0.0.1:255.255.255.0::eth0:off:10.0.0.1"
    "console=serial0,115200"
  ];
  networking.hostName = hostName;

  users.users.mal.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILxOL5huR/1M3pIO0LlW4Z2zSKySUzp3dCqdN3e+TYTU mal@awdbox"
  ];

  nixpkgs.hostPlatform = "aarch64-linux";
  system.stateVersion = "25.05";
}
