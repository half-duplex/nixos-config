{ config, pkgs, lib, ... }:
let
    cfg = config.sconfig.dvorak;
in
{
    options.sconfig.dvorak = lib.mkEnableOption "Use dvorak keyboard system-wide";

    config = lib.mkIf cfg {
        console = {
            keyMap = "dvorak";
        };
        services.xserver = {
            layout = "us";
            xkbVariant = "dvorak";
        };
    };
}
