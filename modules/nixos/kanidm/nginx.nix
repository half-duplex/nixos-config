{
  config,
  flake,
  lib,
  ...
}: let
  inherit (flake.lib) nginxHeaders;
  cfg = config.services.kanidm.server;
  nsCfg = config.mal.services.kanidm;
in {
  options.services.kanidm.server = {
    nginx.enable = lib.mkEnableOption "Configure a nginx reverse proxy";
  };

  config = lib.mkIf cfg.nginx.enable {
    services.kanidm.server.settings = {
      http_client_address_info.x-forward-for = ["::1"];
    };

    services.nginx = lib.mkIf cfg.nginx.enable {
      virtualHosts.${nsCfg.hostname} = {
        inherit (cfg) enableACME;
        onlySSL = true;
        extraConfig = nginxHeaders {
          Content-Security-Policy = {
            font-src = "'self' data:";
            img-src = "'self' data:";
          };
        };
        locations = {
          "/".proxyPass = "https://${cfg.settings.bindaddress}";
        };
      };
    };
  };
}
