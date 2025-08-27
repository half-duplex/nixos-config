{
  config,
  lib,
  namespace,
  pkgs,
  ...
}: {
  options.${namespace}.remoteUnlock.enable = lib.mkEnableOption "Configure remote-unlock for FDE";

  config = lib.mkIf config.${namespace}.remoteUnlock.enable {
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
