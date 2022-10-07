{ config, lib, ... }:
let
  cfg = config.sconfig.remoteUnlock;
in
{
  options.sconfig.remoteUnlock = lib.mkEnableOption "Configure remote-unlock for FDE";

  config = lib.mkIf cfg {
    boot.initrd.network = {
      enable = true;
      postCommands = ''
        echo 'read -t 60 -sp "Enter FDE passphrase: " pw && echo -n "$pw" >/crypt-ramfs/passphrase;echo;exit' >>/root/.profile
      '';
      ssh = {
        enable = true;
        authorizedKeys = config.users.users.mal.openssh.authorizedKeys.keys;
        hostKeys = [
          "/persist/etc/ssh/ssh_host_ed25519_key_initrd"
        ];
      };
    };
    networking.interfaces.eth0.useDHCP = true;
  };
}
