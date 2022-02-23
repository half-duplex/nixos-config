{
  inputs.nixpkgs.url = "nixpkgs/nixos-21.11";
  inputs.unstable.url = "nixpkgs/nixos-unstable";
  inputs.impermanence.url = "github:nix-community/impermanence";

  outputs = { self, nixpkgs, unstable, impermanence, ... }: {
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
      inherit nixpkgs unstable;
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
