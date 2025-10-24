{
  config,
  lib,
  pkgs,
  ...
}: {
  options.mal.remoteUnlock.enable = lib.mkOption {
    default = true;
    description = "Configure remote-unlock for FDE";
    type = lib.types.bool;
  };

  config = lib.mkIf config.mal.remoteUnlock.enable {
    boot.initrd = {
      network = {
        enable = true;
        ssh = {
          enable = true;
          authorizedKeys = config.users.users.mal.openssh.authorizedKeys.keys;
          hostKeys = [
            "/persist/ssh/ssh_host_ed25519_key_initrd"
          ];
        };
      };
      systemd.users.root.shell = "${pkgs.systemd}/bin/systemd-tty-ask-password-agent";
    };
    networking.interfaces.eth0.useDHCP = true;
  };
}
