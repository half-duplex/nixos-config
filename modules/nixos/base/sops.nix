{
  config,
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.sops-nix.nixosModules.default
  ];

  sops = {
    age.sshKeyPaths = map (key: key.path) (builtins.filter (key: key.type == "ed25519") config.services.openssh.hostKeys);
  };
  environment.systemPackages = with pkgs; [sops ssh-to-age];
}
