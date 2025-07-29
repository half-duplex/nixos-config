{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.05";
    nixpkgsStaging.url = "nixpkgs/release-25.05";
    nixpkgsUnstable.url = "nixpkgs/nixos-unstable";
    blank.url = "github:divnix/blank?ref=5a5d2684073d9f563072ed07c871d577a6c614a8";
    intransience = {
      url = "github:anna328p/intransience";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.2";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.pre-commit-hooks-nix.follows = "blank";
    };
    nixos-raspberrypi = {
      url = "github:nvmd/nixos-raspberrypi";
      inputs.argononed.follows = "blank";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    authentik-nix = {
      url = "github:nix-community/authentik-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    cosmopolitan = {
      url = "github:half-duplex/cosmopolitan/s0ph0s-patches";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    werehouse = {
      url = "github:s0ph0s-dog/werehouse";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    inputs.snowfall-lib.mkFlake {
      inherit inputs;
      src = ./.;
      snowfall.namespace = "mal";
      channels-config.allowUnfree = true;
      outputs-builder = channels: {
        formatter = channels.nixpkgs.alejandra;
      };
      systems.modules.nixos = with inputs; [
        authentik-nix.nixosModules.default
        intransience.nixosModules.default
        lanzaboote.nixosModules.lanzaboote
        sops-nix.nixosModules.sops
        werehouse.nixosModules.default
      ];
    };
}
