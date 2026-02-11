{inputs, ...}: {
  nixpkgs.overlays = [
    (_: prev: {
      nixpkgsStaging = import inputs.nixpkgsStaging {
        inherit (prev.stdenv.hostPlatform) system;
        config.allowUnfree = prev.config.allowUnfree;
      };
      #nixpkgsUnstable = import inputs.nixpkgsUnstable {
      #  inherit (prev.stdenv.hostPlatform) system;
      #  config.allowUnfree = prev.config.allowUnfree;
      #};
    })
  ];
}
