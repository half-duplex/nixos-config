{ config, pkgs, lib, ... }:
let
  cfg = config.sconfig.alacritty;
in
{
  options.sconfig.alacritty.enable = lib.mkEnableOption "Enable Alacritty";

  config = lib.mkIf cfg.enable {
    #environment.systemPackages = [ pkgs.alacritty ];
    environment.systemPackages = [
      (pkgs.callPackage
        (pkgs.fetchurl
          {
            url = "https://raw.githubusercontent.com/NixOS/nixpkgs/1ffba9f2f683063c2b14c9f4d12c55ad5f4ed887/pkgs/applications/terminal-emulators/alacritty/default.nix";
            sha256 = "17fde99c1cba26662b06a7c0c8996e66d213d82879b0db18ca90156812c5d863";
          }
        )
        {
          inherit (pkgs.xorg) libXcursor libXxf86vm libXi;
          inherit (pkgs.darwin.apple_sdk.frameworks) AppKit CoreGraphics CoreServices CoreText Foundation OpenGL;
        }
      )
    ];
  };
}
