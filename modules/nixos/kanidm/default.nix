{
  config,
  lib,
  pkgs,
  ...
}: let
  nsCfg = config.mal.services.kanidm;
  cfg = config.services.kanidm.server;
  package = pkgs.kanidm_1_10;
  bindPort = 6286;
in {
  imports = [
    ./acme.nix
    ./checkconfig.nix
    ./db_path.nix
    ./nginx.nix
  ];

  options = let
    inherit (lib) mkOption mkEnableOption types;
  in {
    mal.services.kanidm = {
      enable = mkEnableOption "Configure the Kanidm IDP";
      # idk if it's appropriate to just use settings.origin/settings.domain
      hostname = mkOption {
        default = "id.sec.gd";
        description = "The domain/origin/vhost to configure";
        type = types.str;
      };
    };
    services.kanidm.server = {
      dataDir = mkOption {
        default = dirOf config.services.kanidm.server.settings.db_path;
        description = "Kanidm database and backup path";
        type = types.path;
      };
    };
  };

  config = let
    bind = "[::1]:${toString bindPort}";
  in
    lib.mkIf nsCfg.enable {
      services.kanidm = {
        inherit package;
        # TODO: enable client and unix on other hosts?
        client = {
          enable = true;
          settings.uri =
            "https://"
            + (
              if config.services.kanidm.server.enable
              then bind
              else nsCfg.hostname
            );
        };
        server = {
          enable = true;
          dataDir = "/persist/kanidm";
          enableACME = true;
          nginx.enable = true;
          settings = {
            bindaddress = bind;
            #db_path = "${cfg.dataDir}/kanidm.db"; # see db_path.nix
            db_fs_type = "zfs";
            domain = nsCfg.hostname;
            origin = "https://${nsCfg.hostname}";
            online_backup = {
              path = "${cfg.dataDir}/backups/";
              versions = 15;
            };
          };
        };
        unix = {
          enable = true;
          settings = {
          };
        };
      };
    };
}
