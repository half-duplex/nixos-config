{
  config,
  lib,
  perSystem,
  ...
}: let
  cfg = config.mal.plymouth;
in {
  options.mal.plymouth = {
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
        themePackages = [perSystem.self.plymouth-bgrt-clean-theme];
        # not available in 24.11, so kernelCommandline for now
        #extraConfig = ''
        #  UseSimpledrm=1
        #'';
      };
    };
  };
}
