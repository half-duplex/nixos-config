{
  nixpkgs,
  channels,
  ...
}: final: prev: {
  immich-go = prev.immich-go.overrideAttrs (finalAttrs: prevAttrs: {
    version = "0.24.2";
    src = prev.fetchFromGitHub {
      inherit (prevAttrs.src) owner repo leaveDotGit postFetch;
      rev = "v${finalAttrs.version}";
      hash = "sha256-fw7iq3UrpR25s1+0WzKLd/LBxlJ7V/yFWc7n6ja4wfs=";
    };
    vendorHash = "sha256-mCcp9FMw4NkHJdPEk6cGX/dMGUy79KAulhWb2kiwQnI=";
    doCheck = false;
  });
}
