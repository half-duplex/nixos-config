{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.05";
    nixpkgsStaging.url = "nixpkgs/release-25.05";
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
      url = "github:nix-community/lanzaboote/v0.4.2";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.pre-commit-hooks-nix.follows = "blank";
    };
    lix-module = {
      url = "git+https://git.lix.systems/lix-project/nixos-module?ref=release-2.93";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    blank.url = "github:divnix/blank?ref=5a5d2684073d9f563072ed07c871d577a6c614a8";
    nixos-raspberrypi = {
      url = "github:nvmd/nixos-raspberrypi";
      inputs.argononed.follows = "blank";
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
        # Save inputs from GC
        # https://github.com/NixOS/nix/issues/3995#issuecomment-2081164515
        {
          system.extraDependencies = let
            collectFlakeInputs = input:
              [input]
              ++ builtins.concatMap collectFlakeInputs (
                builtins.attrValues (input.inputs or {})
              );
          in
            builtins.concatMap collectFlakeInputs (builtins.attrValues inputs);
        }
      ];
    };
}
