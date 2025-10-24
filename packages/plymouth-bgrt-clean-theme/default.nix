{
  pname,
  pkgs,
  ...
}: let
  inherit (pkgs) lib;
in
  pkgs.stdenvNoCC.mkDerivation {
    inherit pname;
    version = "1.0.0";

    src = ./source;
    dontBuild = true;
    installPhase = ''
      runHook preInstall

      mkdir -p "$out/share/plymouth/themes/bgrt-clean/images"
      cp * "$out/share/plymouth/themes/bgrt-clean"
      sed -i "s,@packagedir@,$out,g" \
        "$out/share/plymouth/themes/bgrt-clean/bgrt-clean.plymouth"
      cp "${pkgs.plymouth}"/share/plymouth/themes/spinner/*.png \
        "$out/share/plymouth/themes/bgrt-clean/images"
      rm "$out/share/plymouth/themes/bgrt-clean/images/watermark.png" || true

      runHook postInstall
    '';

    meta = {
      description = "Plymouth theme preserving clean BGRT";
      license = lib.licenses.gpl2Plus; # plymouth license
      platforms = lib.platforms.linux;
    };
  }
