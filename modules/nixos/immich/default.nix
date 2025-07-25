{
  config,
  lib,
  namespace,
  pkgs,
  ...
}: let
  inherit (lib.attrsets) mapAttrsToList;
  inherit (lib.lists) toList;
  inherit (lib.strings) concatStringsSep toJSON;

  cfg = config.${namespace}.services.immich;

  immichSettings = {
    ffmpeg = {
      accelDecode = true; # May not work without accel="enabled", but I don't want hw encode
      acceptedAudioCodecs = ["aac" "mp3" "libopus"];
      acceptedContainers = ["mp4" "ogg" "webm"];
      acceptedVideoCodecs = ["h264" "hevc" "vp9" "av1"];
      crf = "30";
      maxBitrate = "10000";
      preset = "medium";
      targetResolution = "1080";
      targetVideoCodec = "av1";
      transcode = "bitrate";
    };
    job = {
      #smartSearch.concurrency = 12;
    };
    machineLearning.clip.modelName = "ViT-B-16-SigLIP-384__webli";
    newVersionCheck.enabled = false;
    oauth = {
      autoLaunch = true;
      autoRegister = true;
      buttonText = "Log in with SSO";
      clientId = "${config.sops.placeholder.oauth_client_id}";
      clientSecret = "${config.sops.placeholder.oauth_client_secret}";
      defaultStorageQuota = 1;
      enabled = true;
      issuerUrl = "https://auth.sec.gd/application/o/photos/";
      #signingAlgorithm = "EdDSA"; # not supported by authentik yet?
    };
    trash.days = 90;
    user.deleteDelay = 90;
  };

  cachePath = "/persist/nobackup/immich/";
in {
  options.${namespace}.services.immich = {
    enable = lib.mkEnableOption "Configure immich";
    nginx = {
      enable = lib.mkOption {
        default = true;
        description = "Configure nginx as a reverse proxy";
        type = lib.types.bool;
      };
      hostname = lib.mkOption {
        default = "photos.sec.gd";
        description = "The nginx vhost to configure";
        type = lib.types.str;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      immich = {
        enable = true;
        accelerationDevices = ["/dev/dri/renderD128"];
        environment = {
          IMMICH_CONFIG_FILE = config.sops.templates."immich.json".path;
        };
        machine-learning.environment = {
          HF_XET_CACHE = cachePath + "huggingface-xet-cache";
          MACHINE_LEARNING_CACHE_FOLDER = lib.mkForce (cachePath + "model-cache");
          MPLCONFIGDIR = cachePath + "matplotlib-cache";
        };
        package = pkgs.nixpkgsUnstable.immich;
        host = "127.0.0.1"; # "localhost" causes v6-only listen
        mediaLocation = "/mnt/data/immich/media";
        settings = null; # let sops write it
      };
      nginx.virtualHosts = lib.mkIf cfg.nginx.enable {
        "${cfg.nginx.hostname}" = {
          onlySSL = true;
          enableACME = true;
          extraConfig = concatStringsSep "\n" (
            mapAttrsToList (k: v: "add_header ${k} ${toJSON (concatStringsSep " " (toList v))} always;") {
              Content-Security-Policy = mapAttrsToList (k: v: "${k} ${concatStringsSep " " (toList v)};") {
                default-src = "'self'";
                connect-src = "'self' https://tiles.immich.cloud/ https://static.immich.cloud/tiles/";
                frame-ancestors = "'self'";
                img-src = "'self' blob: data:";
                script-src = "'self' 'unsafe-inline'";
                style-src = "'self' 'unsafe-inline'";
                worker-src = "'self' blob:";
              };
              Strict-Transport-Security = "max-age=31536000; includeSubdomains; preload";
              X-Content-Type-Options = "nosniff";
              Referrer-Policy = "same-origin";
              Permissions-Policy = "join-ad-interest-group=(), run-ad-auction=(), interest-cohort=()";
            }
            ++ mapAttrsToList (k: v: "${k} ${v};\n") {
              client_max_body_size = "50000M";
              proxy_read_timeout = "600s";
              proxy_send_timeout = "600s";
              send_timeout = "600s";
            }
          );
          locations."/" = {
            proxyPass = "http://127.0.0.1:${toString config.services.immich.port}";
            proxyWebsockets = true;
          };
        };
      };
    };
    sops = {
      secrets =
        lib.genAttrs [
          "oauth_client_id"
          "oauth_client_secret"
        ] (_: {
          sopsFile = secrets/${config.networking.hostName}.yaml;
        });
      templates."immich.json" = {
        mode = "0440";
        owner = "${config.services.immich.user}";
        group = "${config.services.immich.group}";
        restartUnits = ["immich-server.service" "immich-machine-learning.service"];
        content = toJSON immichSettings;
      };
    };
  };
}
