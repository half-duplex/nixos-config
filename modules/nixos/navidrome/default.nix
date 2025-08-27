{
  config,
  lib,
  namespace,
  ...
}: let
  inherit (lib.attrsets) mapAttrsToList;
  inherit (lib.lists) toList;
  inherit (lib.strings) concatStringsSep toJSON;

  cfg = config.${namespace}.services.navidrome;
in {
  options.${namespace}.services.navidrome = {
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
  };

  config = lib.mkIf cfg.enable {
    services = {
      navidrome = {
        enable = true;
        environmentFile = config.sops.secrets."navidrome.env".path;
        settings = {
          BaseURL = "https://${cfg.nginx.hostname}";
          CacheFolder = "/persist/nobackup/navidrome";
          DataFolder = "/persist/navidrome";
          MusicFolder = "/mnt/data/library/music";
          AlbumPlayCountMode = "normalized";
          AutoImportPlaylists = false;
          Backup.Path = "/persist/navidrome/backups";
          Backup.Schedule = "0 7 4 * *";
          Backup.Count = 12;
          DefaultShareExpiration = "720h"; # 30d
          EnableInsightsCollector = true;
          ImageCacheSize = "100MiB";
          PlaylistsPath = "../playlists";
          #ReverseProxyWhitelist = "127.0.0.1";
          TranscodingCacheSize = "500MiB";
        };
      };
      nginx.virtualHosts = lib.mkIf cfg.nginx.enable {
        "${cfg.nginx.hostname}" = {
          onlySSL = true;
          enableACME = true;
          extraConfig = concatStringsSep "\n" (
            mapAttrsToList (k: v: "add_header ${k} ${toJSON (concatStringsSep " " (toList v))} always;") {
              Content-Security-Policy = mapAttrsToList (k: v: "${k} ${concatStringsSep " " (toList v)};") {
                default-src = "'self'";
                img-src = "'self' data:";
                font-src = "'self' data:";
                frame-ancestors = "'none'";
                script-src = "'self' 'unsafe-inline'";
                style-src = "'self' 'unsafe-inline'";
              };
              Strict-Transport-Security = "max-age=31536000; includeSubdomains; preload";
              X-Content-Type-Options = "nosniff";
              Referrer-Policy = "same-origin";
              Permissions-Policy = "join-ad-interest-group=(), run-ad-auction=(), interest-cohort=()";
            }
            ++ mapAttrsToList (k: v: "${k} ${v};\n") {
            }
          );
          locations."/" = {
            proxyPass = "http://127.0.0.1:${toString config.services.navidrome.settings.Port}";
            proxyWebsockets = true;
          };
        };
      };
    };
    systemd.services.navidrome.serviceConfig.BindReadOnlyPaths = "/mnt/data/downloads";
    sops.secrets."navidrome.env" = {
      restartUnits = ["navidrome.service"];
      sopsFile = secrets/${config.networking.hostName}.yaml;
    };
  };
}
