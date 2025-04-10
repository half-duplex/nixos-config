{
  config,
  lib,
  namespace,
  pkgs,
  ...
}: let
  inherit (lib.attrsets) mapAttrsToList;
  inherit (lib.lists) toList;
  inherit (lib.strings) concatStrings concatStringsSep toJSON;

  cfg = config.${namespace}.services.authentik;
in {
  options.${namespace}.services.authentik = {
    enable = lib.mkEnableOption "Configure the authentik IDP";
    nginx = {
      enable = lib.mkOption {
        default = true;
        description = "Configure nginx as a reverse proxy";
        type = lib.types.bool;
      };
      hostname = lib.mkOption {
        default = "auth.sec.gd";
        description = "The nginx vhost to configure";
        type = lib.types.str;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    sops = {
      secrets =
        lib.genAttrs [
          "AUTHENTIK_SECRET_KEY"
          "AUTHENTIK_EMAIL__PASSWORD"
        ] (_: {
          sopsFile = secrets/${config.networking.hostName}.yaml;
        });
      templates."authentik.env" = {
        #mode = "0440";
        #owner = "${config.services.authentik.user}";
        #group = "${config.services.authentik.group}";
        content = concatStringsSep "\n" (mapAttrsToList (k: v: "${k}=${v}")
          ((lib.genAttrs [
              "AUTHENTIK_SECRET_KEY"
              "AUTHENTIK_EMAIL__PASSWORD"
            ] (v: builtins.getAttr v config.sops.placeholder))
            // {
              # Default includes RFC1918 too
              AUTHENTIK_LISTEN__TRUSTED_PROXY_CIDRS = concatStringsSep "," ["127.0.0.1/32" "::1/128"];
            }));
      };
    };
    services = {
      authentik = {
        enable = true;
        environmentFile = config.sops.templates."authentik.env".path;
        nginx = {
          enable = true;
          host = "${cfg.nginx.hostname}";
        };
        settings = {
          avatars = "initials";
          disable_startup_analytics = true;
          email = {
            # TODO
          };
        };
      };
      nginx.virtualHosts = lib.mkIf cfg.nginx.enable {
        ${cfg.nginx.hostname} = {
          # proxy configured by services.authentik
          onlySSL = true;
          enableACME = lib.mkForce true; # override authentik-nix
          extraConfig = concatStrings (
            mapAttrsToList (k: v: "add_header ${k} ${toJSON (concatStringsSep " " (toList v))} always;\n") {
              Content-Security-Policy = mapAttrsToList (k: v: "${k} ${concatStringsSep " " (toList v)};") {
                default-src = "'self'";
                connect-src = "'self'";
                img-src = "'self' data:";
                script-src = "'self' 'unsafe-inline'";
                style-src = "'self' 'unsafe-inline'";
                frame-ancestors = "'none'";
              };
              Strict-Transport-Security = "max-age=31536000; includeSubdomains; preload";
              X-Content-Type-Options = "nosniff";
              Referrer-Policy = "same-origin";
              Permissions-Policy = "join-ad-interest-group=(), run-ad-auction=(), interest-cohort=()";
            }
          );
        };
      };
    };
  };
}
