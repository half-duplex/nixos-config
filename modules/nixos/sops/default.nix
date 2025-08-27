{
  config,
  namespace,
  pkgs,
  ...
}: let
  impermanent = config.${namespace}.impermanence.enable;
in {
  sops = {
    age.sshKeyPaths = [
      ((
          if impermanent
          then "/persist"
          else "/etc"
        )
        + "/ssh/ssh_host_ed25519_key")
    ];
  };
  environment.systemPackages = with pkgs; [sops ssh-to-age];
}
