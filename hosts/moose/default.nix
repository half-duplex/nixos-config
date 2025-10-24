{inputs, ...} @ args: {
  class = "nixos";
  value = inputs.nixos-raspberrypi.lib.nixosSystem {
    modules = [./configuration.nix];
    specialArgs = args // {inherit (inputs) nixos-raspberrypi;};
  };
}
