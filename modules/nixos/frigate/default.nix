{
  config,
  lib,
  namespace,
  pkgs,
  ...
}: let
  cfg = config.${namespace}.services.frigate;
in {
  options.${namespace}.services.frigate = {
    enable = lib.mkEnableOption "Configure Frigate NVR";
    hostname = lib.mkOption {
      default = "panopticon.sec.gd";
      description = "The nginx vhost to configure";
      type = lib.types.str;
    };
    settings = lib.mkOption {
      description = "Additional Frigate settings";
      type = lib.types.submodule {
        freeformType = (pkgs.formats.yaml {}).type;
      };
    };
    directories = {
      # TODO: patch frigate to let me configure its media directories.
      # alternatively, wrap it in a pile of service bind mounts.
      # I am in hell.
    };
  };

  config = lib.mkIf cfg.enable {
    services.frigate = {
      enable = true;
      hostname = cfg.hostname;
      vaapiDriver = "radeonsi";
      settings =
        lib.attrsets.recursiveUpdate {
          auth = {
            enabled = true;
            cookie_secure = true;
            failed_login_rate_limit = "";
            trusted_proxies = ["127.0.0.1" "::1"];
          };
          database.path = "/persist/frigate/frigate.db";
          ui = {
            time_format = "24hour";
            strftime_fmt = "%F %T"; # %R to omit seconds
          };
          ffmpeg.hwaccel_args = "preset-vaapi";
        }
        cfg.settings;
    };
    systemd.services.frigate = {
      serviceConfig = {
        EnvironmentFile = config.sops.secrets."frigate.env".path;
        SupplementaryGroups = ["video"];
      };
    };
    services.go2rtc = {
      # why is this not in the nixpkgs module!!!
      # note: stream aliases are a frigate feature, not go2rtc, and cannot be used here
      enable = builtins.hasAttr "go2rtc" config.services.frigate.settings;
      settings = lib.attrsets.recursiveUpdate cfg.settings.go2rtc {
        # make sure these match what frigate has hardcoded...
        api.listen = ":1984";
        rtsp.listen = ":8554";
        webrtc.listen = ":8555";
      };
    };
    services.nginx.virtualHosts.${cfg.hostname} = {
      # proxy configured by services.frigate
      onlySSL = true;
      enableACME = true;
      # impractical to add security headers to all of the locations =\
    };
    sops.secrets."frigate.env".sopsFile = secrets/${config.networking.hostName}.yaml;
  };
}
