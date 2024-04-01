{
  inputs.nixpkgs.url = "nixpkgs/nixos-23.11";
  inputs.nixpkgsStaging.url = "nixpkgs/release-23.11";
  inputs.nixpkgsUnstable.url = "nixpkgs/nixos-unstable";
  inputs.impermanence.url = "github:nix-community/impermanence";

  outputs = { self, nixpkgs, nixpkgsStaging, nixpkgsUnstable, impermanence, ... }: {
    nixosModules =
      { inherit (impermanence.nixosModules) impermanence; } //
      nixpkgs.lib.mapAttrs'
        (name: type: {
          name = if (type == "regular") then (nixpkgs.lib.removeSuffix ".nix" name) else name;
          value = import (./modules + "/${name}");
        })
        (builtins.readDir ./modules);

    nixosModule = { ... }: {
      imports = builtins.attrValues self.nixosModules;
    };

    nixosConfigurations = self.lib.getHosts {
      path = ./hosts;
      inherit nixpkgs nixpkgsStaging nixpkgsUnstable;
      inherit (self) nixosModule;
    };

    lib = {
      getHosts = import lib/hosts.nix;
      forAllSystems = f: builtins.listToAttrs (map
        (name: { inherit name; value = f name; })
        (builtins.attrNames nixpkgs.legacyPackages)
      );
    };
  };
}
