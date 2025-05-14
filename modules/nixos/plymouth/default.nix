{
  config,
  pkgs,
  lib,
  namespace,
  ...
}: let
  cfg = config.${namespace}.plymouth;
in {
  options.${namespace}.plymouth = {
    enable = lib.mkOption {
      default = true;
      description = "Configure plymouth";
      type = lib.types.bool;
    };
  };

  config = lib.mkIf cfg.enable {
    boot = {
      consoleLogLevel = 3;
      kernelParams = ["plymouth.use-simpledrm"];
      plymouth = {
        enable = true;
        # todo: non-bgrt default
        theme = "bgrt-clean";
        themePackages = [pkgs.mal.plymouth-bgrt-clean-theme];
        # not available in 24.11, so kernelCommandline for now
        #extraConfig = ''
        #  UseSimpledrm=1
        #'';
      };
    };
  };
}
