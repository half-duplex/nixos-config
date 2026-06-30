{...}: {
  imports = [
    ./nixpkgs-newer.nix
    ./electron-builder.nix
    ./ffmpeg.nix
    ./telegram-desktop
  ];
}
