{
  pkgs,
  pname,
  ...
}: let
  inherit (pkgs) fetchurl lib stdenvNoCC;
in
  stdenvNoCC.mkDerivation {
    inherit pname;
    version = "0.1";

    src = fetchurl {
      url = "https://probe.rs/files/69-probe-rs.rules";
      hash = "sha256-0aWcybKxBy0oepqMeTf/rqOwHnCqu6j+X1TRIyj0+eA=";
    };

    dontBuild = true;
    dontUnpack = true;
    strictDeps = true;

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/lib/udev/rules.d"
      pwd
      ls -la
      echo "$src"
      cp "$src" "$out/lib/udev/rules.d/69-probe-rs.rules"

      runHook postInstall
    '';

    meta = {
      description = "The udev rules required for probe-rs to access hardware";
      homepage = "https://probe.rs/docs/getting-started/probe-setup/";
      platforms = lib.platforms.all;
    };
  }
