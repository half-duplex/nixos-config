{
  inputs = {
    # system
    nixpkgs.url = "nixpkgs/nixos-25.11";
    nixpkgsStaging.url = "nixpkgs/release-25.11";
    #nixpkgsUnstable.url = "nixpkgs/nixos-unstable";
    blank.url = "github:divnix/blank?ref=5a5d2684073d9f563072ed07c871d577a6c614a8";
    blueprint = {
      url = "github:numtide/blueprint";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    intransience = {
      url = "github:anna328p/intransience";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.0.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-raspberrypi = {
      url = "github:nvmd/nixos-raspberrypi/develop";
      inputs.argononed.follows = "blank";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # applications
    authentik-nix = {
      url = "github:nix-community/authentik-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    werehouse = {
      url = "git+https://codeberg.org/s0ph0s/werehouse.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    inputs.blueprint {
      inherit inputs;
    };
}
