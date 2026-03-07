{
  config,
  lib,
  ...
}: let
  cfg = config.mal;
  storeKeySopsFile = secrets/${config.networking.hostName}.yaml;
  caches = builtins.removeAttrs {
    "awdbox" = "FAx+su7wzUxR94JhN31M0PVkV3SlLn6Ofuxg3VHA6tg=";
    "awen" = "0EdqqRpCM7okCedZYN3YX1bv7A3Y6Iuo2mO4Ty30w6M=";
  } [config.networking.hostName];
  builders = lib.remove config.networking.hostName cfg.nix-builders.builders;
in {
  options.mal = {
    nix-cache = {
      enable = lib.mkOption {
        default = true;
        description = "Use my other hosts as nix caches";
        type = lib.types.bool;
      };
      serve = lib.mkEnableOption "Serve nix cache";
    };
    nix-builders = {
      enable = lib.mkOption {
        default = true;
        description = "Use remote builders";
        type = lib.types.bool;
      };
      builders = lib.mkOption {
        default = ["awen"];
        description = "Hosts to use as builders";
        type = lib.types.listOf lib.types.str;
      };
      serve = lib.mkEnableOption "Act as a build server";
    };
  };

  config = {
    # cache server or build server
    nix.sshServe = lib.mkIf (cfg.nix-cache.serve || cfg.nix-builders.serve) {
      enable = true;
      protocol = "ssh-ng";
      keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIALi1GW5oe3dH4wmxu85JdIQFkrJeGbVEvAUgHThqAn nix-ssh"];
    };
    users.users.nix-ssh = lib.mkIf config.nix.sshServe.enable {extraGroups = ["ssh-users"];};
    sops.secrets.nixCacheSSHKey.sopsFile = secrets/all-hosts.yaml;

    # cache server
    nix.settings.secret-key-files =
      lib.mkIf (builtins.pathExists storeKeySopsFile || cfg.nix-cache.serve)
      config.sops.secrets.nix-store-key.path;
    sops.secrets.nix-store-key = lib.mkIf (builtins.pathExists storeKeySopsFile) {
      sopsFile = storeKeySopsFile;
    };

    # cache client
    nix.settings.substituters = lib.mkIf cfg.nix-cache.enable (map (
      host: "ssh-ng://nix-ssh@${host}?ssh-key=${config.sops.secrets.nixCacheSSHKey.path}"
    ) (builtins.attrNames caches));
    nix.settings.trusted-public-keys = lib.mkIf cfg.nix-cache.enable (
      lib.attrsets.mapAttrsToList (host: key: "${host}:${key}") caches
    );

    # build client
    nix.buildMachines = lib.mkIf cfg.nix-builders.enable (map (host: {
        hostName = host;
        sshUser = "nix-ssh";
        sshKey = config.sops.secrets.nixCacheSSHKey.path;
        systems = ["x86_64-linux" "aarch64-linux"];
        protocol = "ssh-ng";
        maxJobs = 4;
        speedFactor = 4;
        supportedFeatures = ["big-parallel" "kvm" "nixos-test"];
      })
      builders);
    nix.distributedBuilds = cfg.nix-builders.enable;
    nix.extraOptions = ''
      builders-use-substitutes = true
    '';
  };
}
