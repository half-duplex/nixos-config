{
  config,
  lib,
  namespace,
  pkgs,
  ...
}: {
  sops = {
    age.sshKeyPaths = [
      "/etc/ssh/ssh_host_ed25519_key"
      "/persist/ssh/ssh_host_ed25519_key"
    ];
  };
  environment.systemPackages = with pkgs; [sops ssh-to-age];
}
