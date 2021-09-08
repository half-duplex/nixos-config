{
    inputs.nixpkgs.url = "nixpkgs/nixos-21.05";
    inputs.unstable.url = "nixpkgs/nixos-unstable";
    inputs.impermanence.url = "github:nix-community/impermanence";

    outputs = { self, nixpkgs, unstable, impermanence, ... }: {
        nixosModules = {
            inherit (impermanence.nixosModules) impermanence;

            alacritty = import ./modules/alacritty.nix;
            baseline = import ./modules/baseline.nix;
            cli = import ./modules/cli.nix;
            desktop = import ./modules/desktop.nix;
            dvorak = import ./modules/dvorak.nix;
            #i3 = import ./modules/i3;
            impermanent = import ./modules/impermanent.nix;
            #mouse-dpi = import ./modules/mouse-dpi.nix;
            #pipewire = import ./modules/pipewire.nix;
            plasma = import ./modules/plasma.nix;
            profiles = import ./modules/profiles.nix;
            #scroll-boost = import ./modules/scroll-boost;
            #security-tools = import ./modules/security-tools.nix;
            #server = import ./modules/server.nix;
            #sway = import ./modules/sway.nix;
        };

        nixosModule = { pkgs, ... }: {
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
