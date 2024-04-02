{
  inputs.nixpkgs.url = "nixpkgs/nixos-23.11";
  inputs.nixpkgsStaging.url = "nixpkgs/release-23.11";
  inputs.nixpkgsUnstable.url = "nixpkgs/nixos-unstable";
  inputs.impermanence.url = "github:nix-community/impermanence";
  inputs.lanzaboote = {
    url = "github:nix-community/lanzaboote/v0.3.0";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixpkgsStaging, nixpkgsUnstable, impermanence, lanzaboote, ... }:
    let
      myModules =
        {
          inherit (impermanence.nixosModules) impermanence;
          inherit (lanzaboote.nixosModules) lanzaboote;
        } // nixpkgs.lib.mapAttrs'
          (name: type: {
            name = if (type == "regular") then (nixpkgs.lib.removeSuffix ".nix" name) else name;
            value = import (./modules + "/${name}");
          })
          (builtins.readDir ./modules);
    in {
      nixosModules = myModules // { default.imports = builtins.attrValues myModules; };

      nixosConfigurations = self.lib.getHosts {
        path = ./hosts;
        nixosModule = self.nixosModules.default;
        inherit nixpkgs nixpkgsStaging nixpkgsUnstable;
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
