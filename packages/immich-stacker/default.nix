# Until https://github.com/immich-app/immich/discussions/2479 is implemented
{
  buildGoModule,
  fetchFromGitHub,
  lib,
  ...
}: let
  self = buildGoModule rec {
    pname = "immich-stacker";
    version = "1.6.0";
    src = fetchFromGitHub {
      owner = "mattdavis90";
      repo = "immich-stacker";
      rev = "v${version}";
      hash = "sha256-RDND5nS8VfS3NgFqK/OEhp+Z5R0U0yvdjPeYwTSxEcw=";
    };
    vendorHash = "sha256-Fi7OkzH4o8tUieRHrcak47UI4nu3TC5l2PucpmtY4h4=";
    meta = {
      description = "A small application to help you stack images in Immich";
      homepage = "https://github.com/mattdavis90/immich-stacker";
      license = lib.licenses.mit;
    };
  };
in
  self
