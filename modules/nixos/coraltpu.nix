{
  config,
  lib,
  pkgs,
  ...
}: let
  # These are for the pre-firmware report, as "Global Unichip Corp."
  vendorID = "1a6e";
  productID = "089a";

  cfg = config.mal.coraltpu;
in {
  options.mal.coraltpu.enable = lib.mkEnableOption "Configure udev to load firmware to a USB Coral TPU";
  config = lib.mkIf cfg.enable {
    services.udev.extraRules = let
      libRev = "e35aed18fea2e2d25d98352e5a5bd357c170bd4d";
      fw = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/google-coral/libedgetpu/${libRev}/driver/usb/apex_latest_single_ep.bin";
        hash = "sha256-OwcxGxdLgf0U/SyIf0DWRsDr8vFAzF7lz4vvoPPj3H8=";
      };
      fwcommand = "${pkgs.dfu-util}/bin/dfu-util -D ${fw} -d '${vendorID}:${productID}' -R";
    in (
      ''ACTION=="add", SUBSYSTEM=="usb", ''
      + ''ATTR{idVendor}=="${vendorID}", ATTR{idProduct}=="${productID}", ''
      + ''RUN+="${fwcommand}"''
    );
  };
}
