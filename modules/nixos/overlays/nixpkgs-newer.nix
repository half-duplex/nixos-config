{inputs, ...}: {
  nixpkgs.overlays = [
    (_: prev: {
      nixpkgsStaging = import inputs.nixpkgsStaging {
        inherit (prev) system;
        config.allowUnfree = prev.config.allowUnfree;
      };
      nixpkgsUnstable = import inputs.nixpkgsUnstable {
        inherit (prev) system;
        config.allowUnfree = prev.config.allowUnfree;
      };
    })
  ];
}
