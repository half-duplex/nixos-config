{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-24.11";
    nixpkgsStaging.url = "nixpkgs/release-24.11";
    nixpkgsUnstable.url = "nixpkgs/nixos-unstable";
    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence.url = "github:nix-community/impermanence";
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.3.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lix-module = {
      url = "git+https://git.lix.systems/lix-project/nixos-module?ref=release-2.92";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    authentik-nix = {
      url = "github:nix-community/authentik-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: let
    lib = inputs.snowfall-lib.mkLib {
      inherit inputs;
      src = ./.;
      snowfall = {
        namespace = "mal";
      };
    };
  in
    lib.mkFlake {
      channels-config = {
        allowUnfree = true;
      };
      overlays = with inputs; [
      ];
      systems.modules.nixos = with inputs; [
        authentik-nix.nixosModules.default
        impermanence.nixosModules.impermanence
        lanzaboote.nixosModules.lanzaboote
        lix-module.nixosModules.default
        sops-nix.nixosModules.sops
      ];
    };
}
