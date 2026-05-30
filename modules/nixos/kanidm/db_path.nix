{
  config,
  lib,
  ...
}: let
  cfg = config.services.kanidm.server;
in {
  config = lib.mkIf (cfg.dataDir != "/var/lib/kanidm") {
    # the sane way
    # https://github.com/NixOS/nixpkgs/pull/525759
    #services.kanidm.server.settings.db_path =
    #  "${cfg.dataDir}/kanidm.db";

    # the stupid way
    systemd.services.kanidm = {
      environment = {
        KANIDM_DB_PATH = "${cfg.dataDir}/kanidm.db";
      };
      serviceConfig.BindPaths = [cfg.dataDir];
    };
    systemd.tmpfiles.settings.kanidm."${cfg.dataDir}".d = {
      user = "kanidm";
      group = "kanidm";
      mode = "0700";
    };
  };
}
