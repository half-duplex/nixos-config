# Until https://github.com/immich-app/immich/discussions/2479 is implemented
{
  buildGoModule,
  fetchFromGitHub,
  lib,
  ...
}: let
  self = buildGoModule rec {
    pname = "immich-stacker";
    version = "1.4.0";
    src = fetchFromGitHub {
      owner = "mattdavis90";
      repo = "immich-stacker";
      rev = "b9a7d712c0ee729804ff2baae76bbc1a54b68332";
      hash = "sha256-/qsw+vU02WZXEzcMaXwGGnlHW5uYUbBR47l8CGrqAWE=";
    };
    vendorHash = "sha256-tfgSn9C6ez+/35Ke5lmhtb0D4ey/r4i7Sz7dU7OSTnw=";
    meta = {
      description = "A small application to help you stack images in Immich";
      homepage = "https://github.com/mattdavis90/immich-stacker";
      license = lib.licenses.mit;
    };
  };
in
  self
