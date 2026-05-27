{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.mal.services.frigate;
  secrets = cfg.secrets ++ ["go2rtc_rtmp_password"];
  rtmp_port = 8554;
  webrtc_port = 8555;
in {
  options.mal.services.frigate = {
    enable = lib.mkEnableOption "Configure Frigate NVR";
    useUSBCoral = lib.mkEnableOption "Use a USB Coral TPU for detection";
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
    secrets = lib.mkOption {
      description = "Names of sops/systemd secrets for go2rtc";
      type = lib.types.listOf lib.types.str;
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
      checkConfig = false; # doesn't work when using env vars
      hostname = cfg.hostname;
      vaapiDriver = "radeonsi";
      settings = lib.mkMerge [
        {
          auth = {
            enabled = true;
            cookie_secure = true;
            failed_login_rate_limit = "";
            trusted_proxies = ["127.0.0.1" "::1"];
          };
          database.path = "/persist/frigate/frigate.db";
          ui = {
            time_format = "24hour";
          };
          ffmpeg.hwaccel_args = "preset-vaapi";
        }
        (lib.optionalAttrs cfg.useUSBCoral {
          detectors.coral = {
            type = "edgetpu";
            device = "usb";
          };
        })
        cfg.settings
      ];
    };
    hardware.coral.usb.enable = cfg.useUSBCoral;
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
        # make sure these ports match what frigate has hardcoded...
        # frigate doesn't support auth for the go2rtc api either -.-
        api.listen = ":1984";
        rtsp = {
          listen = ":" + toString rtmp_port;
          username = "stream";
          password = "\${go2rtc_rtmp_password}";
        };
        webrtc.listen = ":" + toString webrtc_port;
      };
    };
    networking.firewall.allowedTCPPorts = [rtmp_port webrtc_port];
    networking.firewall.allowedUDPPorts = [webrtc_port];

    services.nginx.virtualHosts.${cfg.hostname} = {
      # proxy configured by services.frigate
      onlySSL = true;
      enableACME = true;
      # impractical to add security headers to all of the locations =\
    };
    systemd.services.go2rtc.serviceConfig.LoadCredential =
      lib.map (secret: "${secret}:${config.sops.secrets.${secret}.path}") secrets;
    sops.secrets =
      (
        lib.genAttrs secrets (_: {
          restartUnits = ["go2rtc.service"];
          sopsFile = secrets/${config.networking.hostName}.yaml;
        })
      )
      // {
        "frigate.env" = {
          restartUnits = ["frigate.service"];
          sopsFile = secrets/${config.networking.hostName}.yaml;
        };
      };
  };
}
