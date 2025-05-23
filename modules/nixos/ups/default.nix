{
  config,
  lib,
  namespace,
  options,
  ...
}: let
  cfg = config.${namespace}.services.nut;
in {
  options.${namespace}.services.nut = {
    enable = lib.mkEnableOption "Configure Network UPS Tools";
    localCyberPower = lib.mkEnableOption "Configure a local CyberPower UPS";
    users = options.power.ups.users;
  };

  config = lib.mkIf cfg.enable {
    sops.secrets =
      lib.genAttrs (
        map (x: "nut_password_${x}") (builtins.attrNames config.power.ups.users)
      ) (_: {
        sopsFile = lib.mkDefault secrets/${config.networking.hostName}.yaml;
      });
    power.ups = {
      enable = true;
      mode = "netserver";
      users =
        {
          local = {
            upsmon = "primary";
            passwordFile = config.sops.secrets."nut_password_local".path;
          };
        }
        // cfg.users;
      ups.local = lib.mkIf cfg.localCyberPower {
        port = "auto";
        driver = "usbhid-ups";
        directives = ["vendorid = 0764" "productid = 0501"];
      };
      upsd.listen = [{address = "0.0.0.0";}];
      # TODO: add desktop notifications if host is desktop
      # TODO: configure/test OB actions & ensure FSes are RO before UPS shutdown
      upsmon.monitor.local.user = "local";
    };
    networking.firewall.extraInputRules = "ip saddr 10.0.0.0/24 tcp dport 3493 accept";
  };
}
