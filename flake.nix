{
  inputs.nixpkgs.url = "nixpkgs/nixos-24.11";
  inputs.nixpkgsStaging.url = "nixpkgs/release-24.11";
  inputs.nixpkgsUnstable.url = "nixpkgs/nixos-unstable";
  inputs.snowfall-lib = {
    url = "github:snowfallorg/lib";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.impermanence.url = "github:nix-community/impermanence";
  inputs.lanzaboote = {
    url = "github:nix-community/lanzaboote/v0.3.0";
    inputs.nixpkgs.follows = "nixpkgs";
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
        impermanence.nixosModules.impermanence
        lanzaboote.nixosModules.lanzaboote
      ];
    };
}
