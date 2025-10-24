{...}: {
  nixpkgs.overlays = [
    (_: prev: {
      ffmpeg-full = prev.ffmpeg-full.override {
        withUnfree = true;
      };
    })
  ];
}
