# https://github.com/NixOS/nixpkgs/issues/536623
{...}: {
  nixpkgs.overlays = [
    (final: _: {
      pnpm_10_29_2 = final.pnpm_10;
    })
  ];
}
