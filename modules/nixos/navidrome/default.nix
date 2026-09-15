{
  config,
  flake,
  lib,
  ...
}: let
  inherit (flake.lib) nginxHeaders;

  cfg = config.mal.services.navidrome;
in {
  options.mal.services.navidrome = {
    enable = lib.mkEnableOption "Configure navidrome";
    nginx = {
      enable = lib.mkOption {
        default = true;
        description = "Configure nginx as a reverse proxy";
        type = lib.types.bool;
      };
      hostname = lib.mkOption {
        default = "music.sec.gd";
        description = "The nginx vhost to configure";
        type = lib.types.str;
      };
    };
    dataDir = lib.mkOption {
      default = "/persist/navidrome";
      description = "Where to store application data and backups";
      type = lib.types.path;
    };
    cacheDir = lib.mkOption {
      default = "/persist/nobackup/navidrome";
      description = "Directory for caches, like image and transcode";
      type = lib.types.path;
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      navidrome = {
        enable = true;
        environmentFile = config.sops.secrets."navidrome.env".path;
        settings = {
          BaseURL = "https://${cfg.nginx.hostname}";
          CacheFolder = cfg.cacheDir;
          DataFolder = cfg.dataDir;
          MusicFolder = "/mnt/data/library/music";
          AlbumPlayCountMode = "normalized";
          AutoImportPlaylists = false;
          Backup.Path = cfg.dataDir + "/backups";
          Backup.Schedule = "0 7 4 * *";
          Backup.Count = 12;
          DefaultShareExpiration = "720h"; # 30d
          EnableInsightsCollector = true;
          ImageCacheSize = "512MiB";
          PlaylistsPath = "playlists";
          TranscodingCacheSize = "8192MiB";
        };
      };
      nginx.virtualHosts = lib.mkIf cfg.nginx.enable {
        "${cfg.nginx.hostname}" = {
          onlySSL = true;
          enableACME = true;
          extraConfig = nginxHeaders {
            Content-Security-Policy = {
              img-src = "'self' data: blob:";
              font-src = "'self' data:";
              script-src = "'self' 'unsafe-inline'";
              style-src = "'self' 'unsafe-inline'";
            };
          };
          locations."/" = {
            proxyPass = "http://127.0.0.1:${toString config.services.navidrome.settings.Port}";
            proxyWebsockets = true;
          };
        };
      };
    };
    systemd.services.navidrome.serviceConfig.BindReadOnlyPaths = [
      "/mnt/data/downloads"
      "/mnt/data/library/playlists"
    ];
    sops.secrets."navidrome.env" = {
      restartUnits = ["navidrome.service"];
      sopsFile = secrets/${config.networking.hostName}.yaml;
    };
  };
}
