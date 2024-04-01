{ path, nixosModule, nixpkgs, nixpkgsStaging, nixpkgsUnstable }:
let
  hostMetadata = builtins.mapAttrs
    (name: _: import (path + "/${name}"))
    (builtins.readDir path);

  getHostConfig = hostName: hostMeta:
    nixpkgs.lib.nixosSystem {
      inherit (hostMeta) system;
      modules = [
        (nixosModule)
        (hostMeta.module)
        (_: { networking.hostName = hostName; })
        (_: {
          nixpkgs.overlays = [
            (_: _: {
              nixpkgsStaging = import nixpkgsUnstable {
                inherit (hostMeta) system;
                config.allowUnfree = true;
              };
              nixpkgsUnstable = import nixpkgsUnstable {
                inherit (hostMeta) system;
                config.allowUnfree = true;
              };
            })
          ];
        })
      ];
    };
in
builtins.mapAttrs getHostConfig hostMetadata
