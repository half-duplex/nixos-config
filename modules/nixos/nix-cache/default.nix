{
  config,
  lib,
  ...
}: let
  cfg = config.mal.nix-cache;
  storeKeySopsFile = secrets/${config.networking.hostName}.yaml;
  caches = builtins.removeAttrs {
    "awdbox" = "FAx+su7wzUxR94JhN31M0PVkV3SlLn6Ofuxg3VHA6tg=";
    "awen" = "0EdqqRpCM7okCedZYN3YX1bv7A3Y6Iuo2mO4Ty30w6M=";
  } [config.networking.hostName];
in {
  options.mal.nix-cache = {
    enable = lib.mkOption {
      default = true;
      description = "Use my other hosts as nix caches";
      type = lib.types.bool;
    };
    serve.enable = lib.mkEnableOption "Serve nix cache";
  };

  config = lib.mkIf cfg.enable {
    nix.sshServe = {
      enable = true;
      protocol = "ssh-ng";
      keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIALi1GW5oe3dH4wmxu85JdIQFkrJeGbVEvAUgHThqAn nix-ssh"];
    };
    nix.settings = {
      secret-key-files =
        lib.mkIf (builtins.pathExists storeKeySopsFile || cfg.serve.enable)
        config.sops.secrets.nix-store-key.path;
      substituters = map (
        host: "ssh-ng://nix-ssh@${host}?ssh-key=${config.sops.secrets.nixCacheSSHKey.path}"
      ) (builtins.attrNames caches);
      trusted-public-keys = lib.attrsets.mapAttrsToList (host: key: "${host}:${key}") caches;
    };
    users.users.nix-ssh.extraGroups = ["ssh-users"];

    sops.secrets = {
      nixCacheSSHKey.sopsFile = secrets/all-hosts.yaml;
      nix-store-key.sopsFile = storeKeySopsFile;
    };
  };
}
