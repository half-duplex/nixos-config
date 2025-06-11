{inputs, ...}: {
  # Save inputs from GC
  # https://github.com/NixOS/nix/issues/3995#issuecomment-2081164515
  system.extraDependencies = let
    collectFlakeInputs = input:
      [input]
      ++ builtins.concatMap collectFlakeInputs (
        builtins.attrValues (input.inputs or {})
      );
  in
    builtins.concatMap collectFlakeInputs (builtins.attrValues inputs);
}
