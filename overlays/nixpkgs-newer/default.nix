{
  nixpkgs,
  nixpkgsStaging,
  nixpkgsUnstable,
  ...
}: final: prev: {
  nixpkgsStaging = nixpkgsStaging.legacyPackages.${prev.system};
  nixpkgsUnstable = nixpkgsUnstable.legacyPackages.${prev.system};
}
