{
  nixpkgs,
  nixpkgsStaging,
  nixpkgsUnstable,
  ...
}: final: prev: {
  nixpkgsStaging = import nixpkgsStaging {
    inherit (prev) system;
    config.allowUnfree = prev.config.allowUnfree;
  };
  nixpkgsUnstable = import nixpkgsUnstable {
    inherit (prev) system;
    config.allowUnfree = prev.config.allowUnfree;
  };
}
