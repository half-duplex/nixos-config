{namespace, ...}: {
  ${namespace} = {
    hardware = "rpi4";
    remoteUnlock.enable = true;
  };

  boot = {
    #initrd.kernelModules = [];
    kernelParams = ["console=ttyS1"];
  };

  users.users.mal.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILxOL5huR/1M3pIO0LlW4Z2zSKySUzp3dCqdN3e+TYTU mal@awdbox"
  ];

  services.openssh.startWhenNeeded = true;

  system.stateVersion = "24.11";
}
