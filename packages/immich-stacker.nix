# Until https://github.com/immich-app/immich/discussions/2479 is implemented
{
  pname,
  pkgs,
  ...
}: let
  inherit (pkgs) lib buildGoModule fetchFromGitHub;
in
  buildGoModule rec {
    inherit pname;
    version = "1.10.0";
    src = fetchFromGitHub {
      owner = "mattdavis90";
      repo = "immich-stacker";
      rev = "v${version}";
      hash = "sha256-bTNXiTSGmhgXu520NrViD/hijfa+819dOBMRLbAYgPk=";
    };
    vendorHash = "sha256-BsUUsQmEWwMCDX/yjwPDBysPL+RoeQSDz4SIr01zang=";
    meta = {
      description = "A small application to help you stack images in Immich";
      homepage = "https://github.com/mattdavis90/immich-stacker";
      license = lib.licenses.mit;
    };
  }
