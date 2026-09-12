{inputs, ...}: {
  imports = [inputs.multiverse.nixosModules.default];
  multiverse = {
    enable = true;
    config.allowUnfree = true;
  };
}
