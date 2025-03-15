{
  config,
  lib,
  namespace,
  ...
}: {
  options.${namespace}.dvorak = lib.mkOption {
    # Avoid double-remapping on things I'll be using over VNC
    default = builtins.elem config.${namespace}.hardware ["physical" "rpi4"];
    description = "Use dvorak keyboard layout system-wide";
    type = lib.types.bool;
  };

  config = lib.mkIf config.${namespace}.dvorak {
    console = {
      keyMap = "dvorak";
    };
    services.xserver = {
      xkb = {
        layout = "us";
        variant = "dvorak";
      };
    };
  };
}
