# Save inputs from GC
# https://github.com/NixOS/nix/issues/3995#issuecomment-2081164515
{
  config,
  inputs,
  lib,
  ...
}: let
  inherit (builtins) attrValues concatMap;
in {
  options.mal.keepFlakeInputs = lib.mkOption {
    default = true;
    description = ''
      Add flake inputs as extraDependencies to prevent them from being GC'd
    '';
    type = lib.types.bool;
  };

  config = lib.mkIf config.mal.keepFlakeInputs {
    system.extraDependencies = let
      collectFlakeInputs = input:
        [input]
        ++ concatMap collectFlakeInputs (
          attrValues (input.inputs or {})
        );
    in
      concatMap collectFlakeInputs (attrValues inputs);
  };
}
