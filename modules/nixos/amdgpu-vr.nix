{pkgs, config, ...}:
let
  amdgpu-vr = pkgs.callPackage ./package.nix {
    kernel = config.boot.kernelPackages.kernel;
  };
in
{
  #boot.extraModulePackages = [ amdgpu-vr ];
  boot.kernelPatches = [{
    name = "amdgpu-ignore-ctx-privileges";
    patch = pkgs.fetchpatch {
      name = "cap_sys_nice_begone.patch";
      url = "https://github.com/Frogging-Family/community-patches/raw/master/linux61-tkg/cap_sys_nice_begone.mypatch";
      hash = "sha256-Y3a0+x2xvHsfLax/uwycdJf3xLxvVfkfDVqjkxNaYEo=";
    };
  }];
}
