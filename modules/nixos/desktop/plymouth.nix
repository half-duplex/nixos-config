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
    bgrtFallback = lib.mkOption {
      default = null;
      description = "BGRT fallback image";
      type = lib.types.nullOr lib.types.package;
    };
  };

  config = lib.mkIf cfg.enable {
    boot = {
      consoleLogLevel = 3;
      plymouth = {
        enable = true;
        theme = "bgrt-clean";
        themePackages = [
          (perSystem.self.plymouth-bgrt-clean-theme.override {
            bgrtFallback = cfg.bgrtFallback;
          })
        ];
        extraConfig = ''
          UseSimpledrm=1
        '';
      };
    };
  };
}
